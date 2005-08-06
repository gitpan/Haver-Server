package Haver::Server::Listener;
use strict;
use warnings;

use Haver::Session -base;
use Haver::Server::Talker;
use POE::Wheel::SocketFactory;

our $VERSION = 0.03;
our $Alias   = 'Listener';

sub states {
	return [qw(
		_start
		_stop
		_child
		socket_birth
		socket_fail
		listen
		shutdown
	)];
}

sub _start {
	my ($kernel, $heap, $opt) = @_[KERNEL, HEAP, ARG0];

	$heap->{wheels}   = {};
	$heap->{children} = {};
	$heap->{talker}   = $opt->{talker};
	my $config = $heap->{config} = $opt->{config};
	$kernel->alias_set($Alias);
	foreach my $iface (@{ $config->listen }) {
		$kernel->yield('listen', $iface, { nosave => 1 });
	}	
	
	Log("$Alias starts.");
}

sub _stop {
    my ($kernel, $heap) = @_[KERNEL,HEAP];

    Log("$Alias stops.");
}

sub _child {
	my ($kernel, $heap, $type, $kid) = @_[KERNEL, HEAP, ARG0, ARG1];

	if ($type eq 'create' or $type eq 'gain') {
		$heap->{children}{$kid->ID} = 1;
	} elsif ($type eq 'lose') {
		delete $heap->{children}{$kid->ID};
	} else {
		die "I don't know how I got here!\n";
	}
}


sub listen {
	my ($kernel, $heap, $hash, $opt) = @_[KERNEL, HEAP, ARG0, ARG1];
	Log('notice', "Listening on port $hash->{port} with host $hash->{host}");

	unless ($opt->{nosave}) {
		my $l = $heap->{config}->listen;
		push @$l, $hash;
	}
	
	my $wheel = POE::Wheel::SocketFactory->new(
		#BindAddress => $addr,
		BindPort     => $hash->{port},
		Reuse        => 1,
		SuccessEvent => 'socket_birth',
		FailureEvent => 'socket_fail',
	);
	$heap->{wheels}{$wheel->ID} = $wheel;
	$heap->{info}{$wheel->ID}   = $hash;
}

sub socket_birth {
    my ($kernel, $heap, $socket, $address, $port, $wid) =
	@_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];
	
	Log('Socket birth.');
	$heap->{talker}->(
		socket  => $socket,
		address => Socket::inet_ntoa($address),
		port    => $port,
		info    => $heap->{info}{$wid},
	);
}

sub socket_fail {
	my ($kernel, $heap, $operation, $errnum, $errstr, $wid) = @_[KERNEL, HEAP, ARG0..ARG3];
	delete $heap->{wheels}{$wid};

	Log("Listener: Operation '$operation' failed: $errstr ($errnum)\n");
}

sub shutdown {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	Log("Shutting down $Alias.");

	$kernel->alias_remove($Alias);
	
	foreach my $kid (keys %{ $heap->{children} }) {
		$kernel->post($kid, 'shutdown', 'die');
	}
	
	delete $heap->{wheels};
}


1;
