# Haver::Server::Listener,
# this creates a session that listens for connections,
# and when something connects, it spawns
# a Haver::Server::Connection session.
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



package Haver::Server::Listener;
use strict;
use warnings;
use Carp;
use POE qw(
	Wheel::SocketFactory
);

use Haver::Server::Connection;

sub create {
	my ($class) = shift;
	POE::Session->create(
		package_states => 
		[
			$class => [
				'_start',
				'_stop',
				'socket_birth',
				'socket_fail',
			]
		],
		heap => {
		},
		args => [@_],
	);
}

sub _start {
	my ($kernel, $heap, $port) = @_[KERNEL, HEAP, ARG0];

	$kernel->post('Logger', 'note', "Listener Birth on port $port");

	$heap->{listener} = POE::Wheel::SocketFactory->new(
		#BindAddress  => '127.0.0.1',
		BindPort     =>  $port,
		Reuse        => 1,
		SuccessEvent => 'socket_birth',
		FailureEvent => 'socket_fail',
	);
}

sub _stop {
    my ($kernel, $heap) = @_[KERNEL,HEAP];
	delete $heap->{listener};
	delete $heap->{session};
	$kernel->post('Logger', 'note', 'Listener Death');
}


sub socket_birth {
    my ($kernel, $socket, $address, $port) = @_[ KERNEL, ARG0, ARG1, ARG2 ];


	create Haver::Server::Connection ($socket, $address, $port);
}


sub socket_fail {
	die "Bad things!!!";
}

1;
