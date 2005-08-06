# vim: set ts=4 sw=4 noexpandtab si ai sta tw=100:
# This module is copyrighted, see end of file for details.
package Haver::Server::Wheel::Reg;
use strict;
use warnings;

use Haver::Server::Wheel -base;
use Digest;

sub setup {
	my $self = shift;
	$self->msg(
		qw(
			REG:ACCOUNT
			REG:PASSCODE
			REG:EMAIL
		)
	);
}

sub msg_REG_ACCOUNT {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my ($email, $passcode) = @$args;
	my $store = $heap->{store};
	my $user  = $heap->{user};

	unless ($email =~ /^\S+@\S+$/) {
		call('fail', 'invalid.email', $email);
		return;
	}
	if ($store->exists('user', $user->name)) {
		call('fail', 'registered.user', $user->name);
		return;
	}

	$user->passcode($passcode);
	$user->email($email);
	$store->insert($user);
	$heap->{client}->put(['REG:ACCOUNT', $user->name, $email]);
}

sub msg_REG_PASSCODE {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my ($passcode) = @$args;
	my $user = $heap->{user};

	$user->passcode($passcode);
	$heap->{client}->put(['REG:PASSCODE', $user->name]);
}

sub msg_REG_EMAIL {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my ($email) = @$args;
	my $user = $heap->{user};

	$user->email($email);
	$heap->{client}->put(['REG:EMAIL', $user->name, $email]);
}


1;
