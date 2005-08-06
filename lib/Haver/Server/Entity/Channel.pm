# vim: set ts=4 sw=4 expandtab si ai sta tw=104:
# This module is copyrighted, see end of file for details.
package Haver::Server::Entity::Channel;
use strict;
use warnings;
use Haver::Server::Entity -base;

our $VERSION = 0.22;

const namespace  => 'channel';
field _contents  => {};
field owner    => '&root';


sub dump {
    my ($self, $store) = @_;
    my $dump = super($store);
    $dump->{owner} = $self->owner;

    return $dump;
}

sub load {
    my ($this, $data, $store) = @_;
    my $self = super($data, $store);
    $self->owner($data->{owner});

    return $self;
}

sub can_contain {
    my ($self, $object) = @_;
    $object->namespace eq 'user';
}

sub info {
    my $self = shift;
    return (
        owner => $self->owner,
    );
}

sub put {
    my ($self, $msg) = @_;

    foreach my $user ($self->list('user')) {
        $user->put($msg);
    }
}

sub add {
    my ($self, $object) = @_;

    my $ns   = $object->namespace;
    my $name = lc $object->name;

    croak ref($self) . " can't contain $object!" unless $self->can_contain($object);
        
    $self->{_contents}{$ns}{$name} = $object;
}

sub get {
    my ($self, $ns, $name) = @_;
    $name = lc $name;

    return undef unless exists $self->{_contents}{$ns};
    return undef unless exists $self->{_contents}{$ns}{$name};
    return $self->{_contents}{$ns}{$name};
}

sub fetch {
    my $self = shift;
    carp "fetch() is deprecated";
    $self->get(@_);
}

sub remove {
    my ($self, $ns, $name) = @_;
    $name = lc $name; 

    return undef unless exists $self->{_contents}{$ns};
    return undef unless exists $self->{_contents}{$ns}{$name};
    return delete $self->{_contents}{$ns}{$name};
}


sub contents {
    my ($self, $ns) = @_;
    carp "contents() is deprecated. Use list() instead!";
    
    $self->list($ns);
}

sub list {
    my ($self, $ns) = @_;
    my @values = ();
    
    if (exists $self->{_contents}{$ns}) {
        @values = values %{ $self->{_contents}{$ns} };
    } else {
        return ();
    }
    
    return wantarray ? @values : \@values;
}

sub names {
    my ($self, $ns) = @_;
    my @names = ();
    
    if (exists $self->{_contents}{$ns}) {
        @names = keys %{ $self->{_contents}{$ns} };
    } else {
        return ();
    }
    
    return wantarray ? @names : \@names;
}

sub contains {
    my ($self, $ns, $name) = @_;
    
    return undef unless exists $self->{_contents}{$ns};
    return exists $self->{_contents}{$ns}{lc $name};
}

1;
