# vim: set ts=4 sw=4 expandtab si ai sta tw=104:
# This module is copyrighted, see end of file for details.
package Haver::Server::Entity::Lobby;
use strict;
use warnings;
use Haver::Server;
use Haver::Server::Entity::Channel -base;
use Haver::Logger 'Log';

our $VERSION = 0.22;

const name      => '&lobby';
const namespace => 'lobby';
sub version { "Haver::Server/$Haver::Server::VERSION" }

sub can_contain {
    my ($self, $object) = @_;
    $self != $object;
}

sub info {
    my ($self) = shift;
    return (
        super(),
        version => $self->version,
    );
}

sub dump {
    my ($self, $store) = @_;
    my $data = super;
    my @chans = $self->list('channel');
    my @names;

    foreach my $chan (@chans) {
        $store->insert($chan);
        push @names, $chan->name;
    }
    
    $data->{channels} = \@names;
    return $data;
}

sub load {
    my ($this, $data, $store) = @_;
    my $self = super($data);
    foreach my $name (@{ $data->{channels} }) {
        if ($store->exists(channel => $name)) {
            my $chan = $store->fetch(channel => $name);
            $self->add($chan);
        } else {
            Log('error', "Can't load channel $name for lobby.");
        }
    }
    return $self;
}

sub get {
    my ($self, $ns, $name) = @_;
    
    if (is_self($ns, $name)) {
        return $self;
    } else {
        super ($ns, $name);
    }
}

sub contains {
    my ($self, $ns, $name) = @_;

    if (is_self($ns, $name)) {
        return 1;
    } else {
        return super ($ns, $name);
    }
}
sub is_self {
    my ($ns, $name) = @_;
    ( $ns eq 'channel' or $ns eq 'lobby') and $name eq '&lobby';
}

1;
