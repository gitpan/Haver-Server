# vim: set ts=4 sw=4 noexpandtab si ai sta tw=100:
# This module is copyrighted, see end of file for details.
package Haver::Server::Wheel::Main;
use strict;
use warnings;

use Haver::Server::Wheel -base;
use Haver::Util ':all';
use constant PING_TIME => 4 * 60;

sub setup {
	my $self = shift;
	$self->msg(
		qw(
			TO IN BYE POKE PONG
			JOIN OPEN PART LIST
			INFO 
		)
	);

	$self->provide('ping', 'on_ping');
	$self->provide('schedule_ping', 'on_schedule_ping');
}

sub on_load {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	$kernel->yield('schedule_ping');
}

sub on_schedule_ping {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	my $aid = $kernel->alarm_set('ping', time + PING_TIME);
	if (defined $heap->{alarm_send_ping}) {
		$kernel->alarm_remove($heap->{alarm_send_ping});
	}
	
	$heap->{alarm_send_ping} = $aid;
}

sub on_ping {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	my $aid  = $kernel->alarm_set('shutdown', time + PING_TIME, 'ping');
	$heap->{client}->put(['PING', $aid]);
	$heap->{alarm_ping_out} = $aid;
}

sub msg_JOIN {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $lobby = $heap->{lobby};
	my ($name) = @$args;
	my $user   = $heap->{user};
	my $chan   = $lobby->get('channel', $name);

	unless (is_valid_name($name)) {
		call('fail', "invalid.name", $name);
		return;
	}
	unless ($chan) {
		call('fail', 'unknown.channel', $name);
		return;
	}
	if ($chan->contains('user', $user->name)) {
		call('fail', 'already.joined', $name);
		return;
	}

	$user->join($chan);
	$chan->put(['JOIN', $chan->name, $user->name]);
}

sub msg_OPEN {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $lobby = $heap->{lobby};
	my ($name) = @$args;
	
	unless (is_valid_name($name)) {
		call('fail', "invalid.name", $name);
		return;
	}
	if ($lobby->contains('channel', $name)) {
		call('fail', 'exists.channel');
		return;
	}

	$lobby->add(
		new Haver::Server::Entity::Channel (
			name  => $name,
			owner => 'bob',
		)
	);
	$heap->{client}->put(['OPEN', $name]);
	$kernel->yield('msg_JOIN', [$name]);

}

sub msg_PART {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $lobby  = $heap->{lobby};
	my ($name) = @$args;
	my $user   = $heap->{user};
	my $chan   = $lobby->get('channel', $name);

	unless (is_valid_name($name)) {
		call('fail', 'invalid.name', $name);
		return;
	}
	unless ($chan) {
		call('fail', 'unknown.channel', $name);
		return;
	}
	unless ($chan->contains('user', $user->name)) {
		call('fail', 'already.parted', $name);
		return;
	}

	$chan->put(['PART', $chan->name, $user->name]);
	$user->part($chan);
}


sub msg_TO {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $lobby = $heap->{lobby};
	my ($name, $type) = (shift @$args, shift @$args);
	my $user   = $heap->{user};
	my $targ   = $lobby->get('user', $name);


	unless (is_valid_name($name)) {
		call('fail', "invalid.name", $name);
		return;
	}
	unless ($targ) {
		call('fail', 'unknown.user', $name);
		return;
	}
	unless (defined $type) {
		call('fail', 'invalid.type');
		return;
	}


	$targ->put(['FROM', $user->name, $type, @$args]);
}

sub msg_IN {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $lobby = $heap->{lobby};
	my ($name, $type) = (shift @$args, shift @$args);
	my $user   = $heap->{user};
	my $chan   = $lobby->get('channel', $name);


	unless (is_valid_name($name)) {
		call('fail', "invalid.name", $name);
		return;
	}
	unless ($chan) {
		call('fail', 'unknown.channel', $name);
		return;
	}
	unless (defined $type) {
		call('fail', 'invalid.type');
		return;
	}

	$chan->put(['IN', $chan->name, $user->name, $type, @$args]);
}

sub msg_LIST {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $lobby = $heap->{lobby};
	my ($name, $ns) = @$args;
	
	unless (is_valid_name($name)) {
		call('fail', "invalid.name", $name);
		return;
	}
	unless ($lobby->contains('channel', $name)) {
		call('fail', 'unknown.channel', $name);
		return;
	}
	unless (is_known_namespace($ns)) {
		call('fail', 'unknown.namespace', $ns);
		return;
	}
	my $chan = $lobby->get('channel', $name);
	my @items = $chan->list($ns);
	$heap->{client}->put(['LIST', $name, $ns, map { $_->name } @items]);
}

sub msg_INFO {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my ($ns, $name) = @$args;
	my $lobby = $heap->{lobby};
	
	unless (is_valid_name($name)) {
		call('fail', "invalid.name", $name);
		return;
	}
	unless ($lobby->contains($ns, $name)) {
		call('fail', "unknown.$ns", $name);
		return;
	}
	unless (is_known_namespace($ns)) {
		call('fail', 'unknown.namespace', $ns);
		return;
	}

	my $entity = $lobby->get($ns, $name);
	$heap->{client}->put(['INFO', $ns, $name, $entity->info]);


}

sub msg_POKE {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	$heap->{client}->put(['OUCH', $args->[0]]);
	$kernel->yield('schedule_ping');
}

sub msg_PONG {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	
	if (defined $heap->{alarm_ping_out}) {
		$kernel->alarm_remove($heap->{alarm_ping_out});
		$kernel->yield('schedule_ping');
	} else {
		Log('error', "PONG without PING!");
	}
}

sub msg_BYE {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	$kernel->call($_[SESSION], 'shutdown', 'bye', $args->[0]);
}




1;
__END__
=head1 NAME

Haver::Server::Wheel::Message - description

=head1 SYNOPSIS

  use Haver::Server::Wheel::Message;
  # Small code example.

=head1 DESCRIPTION

FIXME

=head1 INHERITENCE

Haver::Server::Wheel::Message extends blaa blaa blaa

=head1 CONSTRUCTOR

List required parameters for new().

=head1 METHODS

This class implements the following methods:

=head2 method1(Z<>)

...

=head1 BUGS

None known. Bug reports are welcome. Please use our bug tracker at
L<http://gna.org/bugs/?func=additem&group=haver>.

=head1 AUTHOR

Dylan William Hardison, E<lt>dhardison@cpan.orgE<gt>

=head1 SEE ALSO

L<http://www.haverdev.org/>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Dylan William Hardison. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this module; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

