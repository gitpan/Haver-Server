# vim: set ts=4 sw=4 noexpandtab si ai sta tw=104:
# This module is copyrighted, see end of file for details.
package Haver::Server::Entity::Avatar;
use strict;
use warnings;
use Haver::Server::Entity -base;

our $VERSION = 0.08;


field -weak    => 'wheel';
field _access  => {};
field passcode => undef;
field address  => '0.0.0.*';
field version  => 'unknown';
field email    => '';

sub initialize {
	my ($self) = @_;
	if (not exists $self->{passcode}) {
		$self->{passcode} = undef;
	}
}

sub put {
	my ($self, $msg) = @_;

	if (my $w = $self->wheel) {
		$w->put($msg);
		return 1;
	} else {
		return undef;
	}
}

sub info {
	my ($self) = @_;
	return (
		address => $self->address,
		version => $self->version,
		$self->email ? (email => $self->email) : (),
	);
}

sub dump {
	my ($self) = @_;
	my $data = super;
	$data->{access}   = $self->_access;
	$data->{passcode} = $self->passcode;
	$data->{email}    = $self->email;
	return $data;
}

sub load {
	my ($this, $data) = @_;
	my $self = super($data);
	$self->_access($data->{access});
	$self->passcode($data->{passcode});
	$self->email($data->{email});

	return $self;
}

sub grant {
	my ($self, $where, $what, $level) = @_;

	$self->{_access}{$where}{$what} = $level || 1;
}

sub revoke {
	my ($self, $where, $what) = @_;

	return undef if not exists $self->{_access}{$where};
	return delete $self->{_access}{$where}{$what};
}

sub may {
	my ($self, $where, $what) = @_;

	return undef unless exists $self->{_access}{$where};
	return undef unless exists $self->{_access}{$where}{$what};
	return $self->{_access}{$where}{$what};
}
