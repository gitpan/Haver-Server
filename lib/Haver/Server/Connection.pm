# Haver::Server::Connection,
# this creates a session, which represents the user...
# 
# Copyright (C) 2003 Dylan William Hardison.
#
# This module is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This module is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this module; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

# TODO, write POD. Soon.

package Haver::Server::Connection;
use strict;
use warnings;
use Carp;
use POE;
use POE::Filter::Line;
use POE::Filter::Stackable;
use POE::Wheel::ReadWrite;
use POE::Driver::SysRW;
use POE::Preprocessor;

use Haver::Protocol;
use Haver::Server::Registry;
use Haver::Server::User;
use Haver::Server::Channel;

use Hash::Util qw(lock_keys);


my %Errors = (
	EWANT           => 'want unsatisfied',
	ECANT_WRONG     => 'cant on unwanted thing',
	EUID_IN_USE     => 'uid is in use',
	EBUG            => 'this should never happen',
	ECMD            => 'unknown command',
	ECID_NOT_FOUND  => 'unknown channel id',
	EUID_NOT_FOUND  => 'unknown user id',
	EALREADY_JOINED => 'already joined to channel',
	ENOT_JOINED     => 'not joined to channel',
);

our @Commands ;

my $Registry = ();

macro assert_channel(myCid) {
	return unless defined myCid;
	($poe_kernel->yield('warn', ECID_NOT_FOUND => myCid), return)
		unless $Registry->has_channel(myCid);
}

macro assert_user(myUid) {
	return unless defined myUid;
	($poe_kernel->yield('warn', EUID_NOT_FOUND => myUid), return)
		unless $Registry->has_user(myUid);
}

sub create {
	my ($class, @args) = @_;

	POE::Session->create(
		package_states => [ 
			$class => {
				# POE states
				'_start'    => '_start',
				'_stop'     => '_stop',
				'_default'  => '_default',
				
				# Wheel states
				'socket_input'  => 'socket_input',
				'socket_error'  => 'socket_error',
				'socket_flush'  => 'socket_flush',
				
				# Utility states
				'send'      => 'on_send',
				'want'      => 'on_want',
				'shutdown'  => 'on_shutdown',
				'close'     => 'on_close',
				'warn'      => 'on_warn',
				'die'       => 'on_die',

				# User states
				map { ("cmd_$_" => "cmd_$_") } qw(
					UID VERSION CANT
					MSG ACT
					PMSG PACT
					JOIN PART
					CHANS USERS
				),
			}
		],
		heap => {},
		args => \@args,
	);

	$Registry = instance Haver::Server::Registry;
	$Registry->add_channel(
		new Haver::Server::Channel(cid => 'lobby')
	);
}


sub _start {
	my ($heap, $session, $kernel, $socket, $address, $port ) = 
	@_[ HEAP,  SESSION,  KERNEL,  ARG0,    ARG1,     ARG2];
	$address = Socket::inet_ntoa($address);
	
    $kernel->post('Logger', 'note',  'Socket Birth');
	$kernel->post('Logger', 'note', "Connection from ${address}:$port");

	
	my $sock = new POE::Wheel::ReadWrite(
		Handle => $socket,
		Driver => new POE::Driver::SysRW,
		Filter => new Haver::Protocol::Filter,
		InputEvent   => 'socket_input',
		FlushedEvent => 'socket_flush',
		ErrorEvent   => 'socket_error',
	);


	my $timer = $kernel->alarm_set(
		'close', 
		time + 20,
		"Connection timeout"
	);

	%$heap = (
		TIMEOUT       => $timer,
		SOCKET        => $sock,
		ADDRESS       => $address,
		PORT          => $port,
		SHUTDOWN      => 0,
		IGNORE        => 0,
		WANT          => undef,
		WANT_ACTION   => undef, # called if CANT $WANT...
		VERSION       => undef,
		USER          => undef,
		UID           => undef,
	);
	lock_keys(%$heap);

	$kernel->yield('want', 'VERSION', sub {
			$kernel->yield('close', q(Mommy says I shouldn't talk to strangers.));
		}
	);

}


sub _stop {
	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

	print "STOPPING CONNECTION\n";
	my ($address, $port) = @$heap{qw(ADDRESS PORT)};
    $kernel->call('Logger', 'note',  'Socket Death');
	$kernel->call('Logger', 'note', "Lost connection from ${address}:$port");
}


sub _default {
	my ($kernel, $heap, $event, $args) = @_[KERNEL, HEAP, ARG0, ARG1];


	if ($event =~ s/^cmd_//) {
		$kernel->yield('warn', ECMD => $event);
	}
	$kernel->post('Logger', 'error', "Unknown event: $event");

	return 0;
}








sub socket_input {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];

	return if $heap->{IGNORE};
	
	$kernel->post('Logger', 'rawlog', join("\t", @$args));

	my $cmd = shift @$args;

	if ($heap->{WANT} and $cmd ne 'CANT') {
		if ($cmd eq $heap->{WANT}) {
			$heap->{WANT} = undef;
			$heap->{WANT_ACTION} = undef;
		} else {
			$kernel->yield('die', EWANT => $cmd);
			return;
		}
	}

	$kernel->yield("cmd_$cmd", $args);
}

sub socket_flush {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	if ($heap->{SHUTDOWN}) {
		$heap->{SOCKET} = undef;
	}
}

sub socket_error {
	my ($kernel, $heap, $operation, $errnum, $errstr) = @_[KERNEL, HEAP, ARG0..ARG3];

	$kernel->post('Logger', 'error', 
		"Socket generated $operation error ${errnum}: $errstr");

	$heap->{SOCKET} = undef;
	$kernel->yield('shutdown');
}



sub on_send {
	my ($kernel, $heap, @msgs) = @_[KERNEL, HEAP, ARG0 .. $#_];
	$heap->{SOCKET}->put(@msgs) if $heap->{SOCKET};
}

sub on_close {
	my ($kernel, $heap, $session, $reason) = @_[KERNEL, HEAP, SESSION, ARG0];
	$kernel->call($session, 'send', ['CLOSE', $reason]);
	$kernel->yield('shutdown');
}

sub on_want {
	my ($kernel, $heap, $want, $code) = @_[KERNEL, HEAP, ARG0, ARG1];

	$want =~ s/\W//g;
	$want = uc $want;

	$heap->{WANT} = $want;
	$heap->{WANT_ACTION} = $code;
	$kernel->yield('send', ['WANT', $want]);
}

sub on_shutdown {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	if (!$heap->{SHUTDOWN}) {
		$kernel->post('Logger', 'note', 'Shutting down client session.');
		my $user = $heap->{USER};
		my $uid  = $heap->{UID};
		$heap->{SHUTDOWN} = 1;
		$heap->{USER} = undef;
		$heap->{UID} = undef;
		
		$kernel->alarm_remove_all();
		if ($Registry->remove_user($uid)) {
			foreach my $chan ($user->subscriptions_by_val) {
				$user->unsubscribe($chan);
				$chan->remove($user);
				$chan->send(['PART', $chan->cid, $uid]);
			}
		}

	} else {
		$kernel->post('Logger', 'error', 'Trying to shutdown more than once!');
	}
}

sub on_die {
	my ($kernel, $heap, $err, $data) = @_[KERNEL, HEAP, ARG0, ARG1];

	my $emsg = $Errors{$err} or die "No description for $err!";
	$kernel->yield('send', ['DIE', $err, $data, $emsg]);
	$kernel->yield('close', 'died');
}

sub on_warn {
	my ($kernel, $heap, $err, $data) = @_[KERNEL, HEAP, ARG0, ARG1];
	$data ||= '';
	
	my $emsg = $Errors{$err} or die "No description for $err!";
	$kernel->yield('send', ['WARN', $err, $data, $emsg]);
}

sub cmd_CANT {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $want = $args->[0];
	
	if ($want eq $heap->{WANT}) {
		if (my $code = $heap->{WANT_ACTION}) {
			$code->($kernel, $heap);
		} else {
			$heap->{WANT} = undef;
		}
	} else {
		$kernel->yield('die', ECANT_WRONG => $want);
	}
}


sub cmd_VERSION {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $ver = $args->[0];

	if ($ver) {
		$heap->{VERSION} = $ver;
		$kernel->yield('want', 'UID', sub {
				$kernel->yield('close', 'a rose by any other name...');
			}
		);
	} else {
		$kernel->yield('die', EBADVER => $ver);
	}
}

sub cmd_UID {
	my ($kernel, $heap, $args, $ses) = @_[KERNEL, HEAP, ARG0, SESSION];
	my $uid = $args->[0];
	my $user = new Haver::Server::User(
		uid  => $uid,
		sid => $ses->ID,
	);

	if (not $Registry->has_user($uid)) {
		$Registry->add_user($user);
		$kernel->yield('send', ['ACCEPT', $uid]);
		$heap->{USER} = $user;
		$heap->{UID}  = $uid;
		$kernel->alarm_remove($heap->{TIMEOUT});
		$heap->{TIMEOUT} = undef;
	} else {
		#if ($Registry->has_user($uid)) {
		$kernel->yield('send', ['REJECT', $uid, 'EUID_IN_USE', $Errors{EUID_IN_USE}]);
		#} else {
		#	$kernel->yield('send', ['REJECT', $uid, 'EBUG', $Errors{EBUG}]);
		#}
	}
}


# MSG($cid, $msg)
# ACT($cid, $msg)
macro make_CMD(CMD) {
	sub cmd_CMD {
		my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
		my $user = $heap->{USER};
		my $cid = $args->[0];
		my $msg = $args->[1];

		{% assert_channel $cid %}
	
		my $chan = $Registry->fetch_channel($cid);
		$chan->send(['CMD', $cid, $heap->{UID}, $msg]);
	}
}

{% make_CMD MSG %}
{% make_CMD ACT %}


# JOIN($cid)
sub cmd_JOIN {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $cid  = $args->[0];
	my $user = $heap->{USER};
	my $uid  = $heap->{UID};
	
	{% assert_channel $cid %}

	unless ($user->is_subscribed($cid)) {
		my $chan = $Registry->fetch_channel($cid);
		$chan->add($user);
		$user->subscribe($chan);
		$chan->send(['JOIN', $cid, $uid]);
	} else {
		$kernel->yield('warn', EALREADY_JOINED => $cid);
	}
}

# PART($cid)
sub cmd_PART {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $cid = $args->[0];
	my $user = $heap->{USER};
	my $uid  = $heap->{UID};

	{% assert_channel $cid %}

	if ($user->is_subscribed($cid)) {
		my $chan = $Registry->fetch_channel($cid);
		$chan->send(['PART', $cid, $uid]);
		$chan->remove($user);
		$user->unsubscribe($chan);
	} else {
		$kernel->yield('warn', ENOT_JOINED => $cid);
	}
}

# CHANS()
sub cmd_CHANS {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield('send', ['CHANS', $Registry->list_channels_by_id]);
}

sub cmd_USERS {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $cid = $args->[0];
	my $user = $heap->{USER};
	my $uid  = $heap->{UID};

	{% assert_channel $cid %}
	my $chan = $Registry->fetch_channel($cid);

	$kernel->yield('send', ['USERS', $cid, $chan->uidlist]);
}

# PMSG($uid, $msg)
# PACT($uid, $msg)
macro make_PCMD(CMD) {
	sub cmd_CMD {
		my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
		my $target_uid = $args->[0];
		my $user       = $heap->{USER};
		my $uid        = $heap->{UID};

		{% assert_user $target_uid %}
		my $target = $Registry->fetch_user($target_uid);

		$target->send(['CMD', $uid, $args->[1]]);
	}
}

{% make_PCMD PMSG %}
{% make_PCMD PACT %}

1;
