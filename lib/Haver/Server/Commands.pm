# Haver::Server::Commands,
# Commands for Haver::Server::Connection.
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
package Haver::Server::Commands;
use strict;
use warnings;
use Carp;
use POE;
use POE::Preprocessor;

use Haver::Server qw( $Registry );
use Haver::Protocol::Errors qw( %Errors   );
use Digest::SHA1 qw(sha1_base64);

our @Commands = qw(
	UID PASS VERSION CANT
	MSG ACT PMSG PACT
	JOIN PART QUIT
	USERS CHANS PONG
);

const PING_TIME  (1 * 60)
macro assert_channel(myCid) {
	return unless defined myCid;
	($poe_kernel->yield('warn', CID_NOT_FOUND => myCid), return)
		unless $Registry->contains('channel', myCid);
}
macro assert_user(myUid) {
	return unless defined myUid;

	($poe_kernel->yield('warn', UID_INVALID => myUid), return)
		unless Haver::Server::User->valid_uid(myUid);
	($poe_kernel->yield('warn', UID_NOT_FOUND => myUid), return)
		unless myUid eq '.' or $Registry->contains('user', myUid);
}

sub commands {
	my ($this) = @_;
	
	return { map {("cmd_$_" => "cmd_$_")} @Commands };
}


sub cmd_UID {
	my ($kernel, $heap, $args, $ses) = @_[KERNEL, HEAP, ARG0, SESSION];
	my $uid = $args->[0];
	
	return if $heap->{uid};

	if ($uid eq '.') {
		$kernel->yield('reject', $uid, 'UID_RESERVED');
		return;
	}
	
	unless (Haver::Server::User->valid_uid($uid)) {
		$kernel->yield('reject', $uid, 'UID_INVALID');
		return;
	}
	
	my $user = new Haver::Server::User(
		id  => $uid,
		sid => $ses->ID,
	);
	eval { $user->load($Registry->get_field('DataDir')) };

	if (not $Registry->contains(user => $uid)) {
		unless ($user->password) {
			$kernel->yield('accept', $uid, $user);
		} else {
			$kernel->yield('askpass', $uid, $user);
		}
	} else {
		$kernel->yield('reject', $uid, 'UID_IN_USE');
	}
}
sub cmd_PASS {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $uid    =  delete $heap->{want_data}{uid};
	my $user   = delete $heap->{want_data}{user};
	my $salt   = delete $heap->{want_data}{salt};
	my $result = $args->[0];

	if ($result eq sha1_base64($user->password . $salt)) {
		$kernel->yield('accept', $uid, $user);
	} else {
		$kernel->yield('reject', $uid, 'PASS_INVALID');
	}
	
}

sub cmd_VERSION {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $ver = $args->[0];

	if ($ver) {
		$kernel->yield('want', 'UID',
			version => $ver,
			code => sub {
				$kernel->yield('die', 'WANT', 'UID');
			},
		);
	} else {
		$kernel->yield('die', BADVER => $ver);
	}
}


sub cmd_CANT {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $want = $args->[0];
	
	if ($want eq $heap->{WANT}) {
		if (my $code = delete $heap->{want_data}{code}) {
			$code->($kernel, $heap);
		}
		$heap->{WANT} = undef;
	} else {
		$kernel->yield('die', CANT_WRONG => $want);
	}
}

macro make_CMD(CMD) {
	sub cmd_CMD {
		my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
		my $user = $heap->{user};
		my $cid = $args->[0];
		my $msg = $args->[1];

		{% assert_channel $cid %}
		unless ($msg) {
			$kernel->yield('die', 'ARG_INVALID', 'CMD', 2);
			return;
		}
	
		my $chan = $Registry->fetch('channel', $cid);
		$chan->send(['CMD', $cid, $heap->{uid}, $msg]);
	}
}

{% make_CMD MSG %}
{% make_CMD ACT %}


sub cmd_JOIN {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $cid  = $args->[0];
	my $user = $heap->{user};
	my $uid  = $heap->{uid};
	
	{% assert_channel $cid %}

	unless ($user->contains('channel', $cid)) {
		my $chan = $Registry->fetch('channel', $cid);
		$chan->add($user);
		$user->add($chan);
		$chan->send(['JOIN', $cid, $uid]);
	} else {
		$kernel->yield('warn', ALREADY_JOINED => $cid);
	}
}
sub cmd_PART {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $cid = $args->[0];
	my $user = $heap->{user};
	my $uid  = $heap->{uid};

	{% assert_channel $cid %}

	if ($user->is_subscribed($cid)) {
		my $chan = $Registry->fetch('channel', $cid);
		$chan->send(['PART', $cid, $uid]);
		$chan->remove($user);
		$user->remove($chan);
	} else {
		$kernel->yield('warn', NOT_JOINED_PART => $cid);
	}
}
sub cmd_QUIT {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield('bye', 'ACTIVE');
}


sub cmd_CHANS {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield('send', ['CHANS', $Registry->list_ids('channel')]);
}
sub cmd_USERS {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $cid = $args->[0];
	my $user = $heap->{user};
	my $uid  = $heap->{uid};

	{% assert_channel $cid %}
	my $chan = $Registry->fetch('channel', $cid);


	$kernel->yield('send', ['USERS', $cid, $chan->list_ids('user')]);
}


macro make_PCMD(CMD) {
	sub cmd_CMD {
		my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
		my $target_uid = $args->[0];
		my $msg        = $args->[1];
		my $user       = $heap->{user};
		my $uid        = $heap->{uid};

		{% assert_user $target_uid %}
		my $target = $Registry->fetch('user', $target_uid);
		unless (defined $msg) {
			$kernel->yield('warn', 'ARG_INVALID', 'CMD', 2);
			return;
		}


		$target->send(['CMD', $uid, $msg]);
	}
}
{% make_PCMD PMSG %}
{% make_PCMD PACT %}

# QUIT

# PONG($data)
sub cmd_PONG {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];

}

1;
