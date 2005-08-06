# vim: set ts=4 sw=4 noexpandtab si ai sta tw=100:
# This module is copyrighted, see end of file for details.
package Haver::Server::Wheel::Auth;
use strict;
use warnings;

use Haver::Server::Wheel -base;
use Digest;

sub setup {
	my $self = shift;
	$self->msg(
		qw(
			AUTH:TYPE
			AUTH:BASIC
		)
	);

	$self->provide('auth_ok', 'on_auth_ok');
}

sub on_auth_ok {
	my ($kernel, $heap, $user) = @_[KERNEL, HEAP, ARG0];
	Log('notice', "client is authorized as $heap->{name}");
	$heap->{loader}->unload_wheel(__PACKAGE__);
	$kernel->yield('accept', delete $heap->{name}, $user);
}

sub msg_AUTH_TYPE {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my $config = $heap->{config};
	my $type = $args->[0];
	if ($type eq 'AUTH:BASIC') {
		$heap->{nonce} = rand_word();
		$heap->{client}->put([
				'AUTH:BASIC',
				$heap->{nonce},
				keys %{ $config->digests },
			]
		);
	}
}

sub msg_AUTH_BASIC {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my ($digest, $resp) = @$args;
	my $digests = $heap->{config}->digests;
	my $store = $heap->{store};
	my $name = $heap->{name};
	my $user = $store->fetch(user => $name);
	$user->name($name);

	unless (exists $digests->{$digest}) {
		call('fail', 'unknown.digest');
		return;
	}
	my $hasher = Digest->new($digests->{$digest});
	$hasher->add($heap->{nonce});
	$hasher->add($user->passcode);
	my $need = $hasher->b64digest;
	
	Log('debug', "'$need' == '$resp'");
	if ($need eq $resp) {
		$kernel->yield('auth_ok', $user);
	} else {
		call('fail', 'auth.fail', $name, $digest);
	}
}

sub rand_char { chr(int(rand(93)) + 33) }
sub rand_word {
	my $len = 26;
	my @char;
	for (1 .. $len) {
		push @char, rand_char();
	}
	join('', @char);
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

