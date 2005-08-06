# vim: set ts=4 sw=4 noexpandtab si ai sta tw=100:
# This module is copyrighted, see end of file for details.
package Haver::Server::Entity::User;
use strict;
use warnings;
use Haver::Server::Entity::Avatar -base;

const (namespace   => 'user');


sub join {
	my ($self, $chan) = @_;
	$chan->add($self);
	$self->add_channel($chan->name);
}

sub part {
	my ($self, $chan) = @_;
	$chan->remove($self->namespace, $self->name);
	$self->remove_channel($chan->name);
}

sub add_channel {
	my ($self, $name) = @_;
	$self->{channels}{$name} = 1;
}

sub remove_channel {
	my ($self, $name) = @_;
	delete $self->{channels}{$name};
}

sub channels {
	my ($self) = @_;
	keys %{ $self->{channels} };
}

1;
