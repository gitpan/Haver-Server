# vim: set ts=4 sw=4 noexpandtab si ai sta tw=100:
# This module is copyrighted, see end of file for details.
package Haver::Server::Wheel::Login;
use strict;
use warnings;

use Haver::Server::Wheel -base;
use Haver::Server::Wheel::Auth;
use Haver::Server::Wheel::Reg;
use Haver::Util qw( :name );

our $VERSION = 0.02;

sub setup {
	my $self = shift;
	$self->msg('HAVER');
	$self->provide('accept', 'on_accept');
}

sub msg_HAVER {
	my ($self, $kernel, $heap, $args) = @_[OBJECT, KERNEL, HEAP, ARG0];
	my ($version, $ext) = @$args;

	Log('notice', 'Client is ' . $version);
	$heap->{client}->put(
		['HAVER', $heap->{info}{host}, $heap->{lobby}->version]);
	$heap->{version} = $version;
	my %ext;
	if ($ext) {
		foreach my $n (split(/,/, $ext)) {
			$ext{$n} = 1;
		}
	}
	$heap->{extensions} = \%ext;
	$self->undefine('msg_HAVER');
	$self->define('msg_IDENT', 'msg_IDENT');
}

sub msg_IDENT {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my ($name) = @$args;
	my $lobby  = $heap->{lobby};
	my $store  = $heap->{store};
	my $ns = 'user';
	
	if ($lobby->contains($ns, $name)) {
		call('fail', "exists.$ns", $name);
	} elsif (not is_valid_name($name)) {
		call('fail', "invalid.name", $name);
	} elsif ($ns eq 'user' and is_reserved_name($name)) {
		call('fail', "reserved.$ns", $name);
	} elsif ($store->exists($ns, $name)) {
		$heap->{name} = $name;
		if (exists $heap->{extensions}{auth}) {
			$heap->{client}->put(['AUTH:TYPES', 'AUTH:BASIC']);
			$heap->{loader}->load_wheel('Haver::Server::Wheel::Auth');
		} else {
			call('fail', 'auth.impossible');
		}
	} else {
		my $user = new Haver::Server::Entity::User (
			name  => $name,
		);
		$kernel->yield('accept', $name, $user);
	}
}

sub on_accept {
	my ($kernel, $heap, $name, $user) = @_[KERNEL, HEAP, ARG0, ARG1];
	my $lobby  = $heap->{lobby};


	$user->wheel($heap->{client});
	$user->version($heap->{version});
	$user->address($heap->{address});
	$lobby->add($user);
	$heap->{user} = $user;
	$heap->{client}->put(['HELLO', $name]);
	$heap->{loader}->unload_wheel(__PACKAGE__);
	$heap->{loader}->load_wheel('Haver::Server::Wheel::Main');
	$heap->{loader}->load_wheel('Haver::Server::Wheel::Reg');
}



1;
__END__
=head1 NAME

Haver::Server::Wheel::Login - description

=head1 SYNOPSIS

  use Haver::Server::Wheel::Login;
  # Small code example.

=head1 DESCRIPTION

FIXME

=head1 INHERITENCE

Haver::Server::Wheel::Login extends blaa blaa blaa

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

