package Haver::Server::Talker;
use strict;
use warnings;

use Haver::Session -base;
use Haver::Protocol::Filter;
use Haver::Server;
use Haver::Wheel::Loader;
use Haver::Server::Wheel::Login;
use Haver::Server::Wheel::Main;


use POE::Wheel::ReadWrite;
use POE::Driver::SysRW;

our $VERSION = '0.08';

sub states {
	return [qw(
		_start _stop _default
		input error flush
		shutdown fail
	)];
}

sub _start {
	my ($heap, $session, $kernel, $opt) = @_[ HEAP,  SESSION,  KERNEL, ARG0];
	my ($address, $socket, $port) = ($opt->{address}, delete $opt->{socket}, $opt->{port});
	
	Log('notice', "Talker for $address:$port starts");
	binmode $socket, ":utf8";
	my $client = new POE::Wheel::ReadWrite(
		Handle       => $socket,
		Driver       => new POE::Driver::SysRW,
		Filter       => new Haver::Protocol::Filter,
		InputEvent   => 'input',
		FlushedEvent => 'flush',
		ErrorEvent   => 'error',
	);

	%$heap = (
		%$opt,
		client   => $client,
		loader   => new Haver::Wheel::Loader,
	);
	croak "no lobby!" unless defined $heap->{lobby};
	$heap->{loader}->load_wheel('Haver::Server::Wheel::Login');
}


sub _stop {
	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

	my ($address, $port) = @$heap{qw(address port)};
	Log('notice', "Talker for ${address}:$port stops");
}


sub _default {
	my ($kernel, $heap, $name, $args) = @_[KERNEL, HEAP, ARG0, ARG1];
	my $cmd = $args->[1];
	if ($name =~ /^msg_/) {
		if (not $heap->{version}) {
			Log('warning', "Client issued unknown command ($cmd) before HAVER.");
			Log('warning', 'Probably a search engine...');
			$heap->{error} = 1;
			$heap->{client} = undef;
			post('shutdown');
		} else {
			Log('warning', "Client isseud unknown command $cmd");
			call('fail', 'unknown.cmd');
		}
	}

	0;
}

sub input {
	my ($kernel, $heap, $args, $session) = @_[KERNEL, HEAP, ARG0, SESSION];
	
	my @copy = @$args;
	return if $heap->{plonk};
	return if $heap->{shutdown};

	my $cmd = shift @$args;
	my $event = 'msg_' . $cmd;
	
	Log('info', "Command: '$cmd'");
	$heap->{cmd} = $cmd;
	call('schedule_ping');
	call($event, $args, $cmd);
}

sub fail {
	my ($kernel, $heap, $err, @args) = @_[KERNEL, HEAP, ARG0 .. $#_];
	Log('info', "Failing client on command $heap->{cmd} with error $err");
	$heap->{client}->put(['FAIL', $heap->{cmd}, $err, @args]);
}


sub error {
	my ($kernel, $heap, $operation, $errnum, $errstr) = @_[KERNEL, HEAP, ARG0..ARG3];
	my @why;
	
	if ($errnum == 0) {
		@why = ('closed');
	} else {
		Log('error',
			"Talker for $heap->{address}:$heap->{port}: ",
			"Socket generated $operation error ${errnum}: $errstr");
		@why = ('error', $errstr);
	}
	
	$heap->{error} = 1;
	delete $heap->{client};
	post('shutdown', @why);
}


sub shutdown {
	my ($kernel, $heap, $session, @why) = @_[KERNEL, HEAP, SESSION, ARG0 .. $#_];
	my $lobby = $heap->{lobby};
	my $store = $heap->{store};
	
	if ($heap->{shutdown}) {
		Log('critical', 'Race condition: shutdown called more than once!');
	}
	Log('info', "Shutting down talker for $heap->{address}:$heap->{port}");
	
	$heap->{shutdown} = 1;
	if (@why) {
		if ($heap->{user}) {
			my $user = delete $heap->{user};
			$store->insert($user) if defined $user->passcode;
			$lobby->remove($user->namespace, $user->name);
			my %seen;
			foreach my $name ($user->channels) {
				my $chan = $lobby->get('channel', $name);
				$user->part($chan);
				foreach my $u ($chan->list('user')) {
					unless ($seen{ $u->name }++) {
						$u->put(['QUIT', $user->name, @why]);
					}	
				}
			}
		} else {
			Log('error', "\$heap->{user} not defined in shutdown");
		}
		
		if ($heap->{client}) {
			$heap->{client}->put(['BYE', @why]);
		} else {
			Log('error', "\$heap->{client} not defined in shutdown");
		}
	} else {
		delete $heap->{client};
	}
	$kernel->alarm_remove_all();
}

sub flush {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	Log('warning', "Flush happened after an error") if $heap->{error};
	if ($heap->{shutdown}) {
		delete $heap->{client};
	}
}



1;
