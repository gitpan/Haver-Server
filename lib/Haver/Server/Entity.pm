# vim: set ts=4 sw=4 expandtab si ai sta tw=104:
# This module is copyrighted, see end of file for details.
package Haver::Server::Entity;
use strict;
use warnings;
use Haver::Base -base;
use Haver::Util;

field attr   => {};
stub 'namespace';
stub 'put';
stub 'info';

sub initialize {
    my ($self) = @_;
    if (not exists $self->{name}) {
        $self->{name} = '&undef';
    }
}

sub name {
    my $self = shift;
    if (@_ == 0) {
        return $self->{name};
    } else {
        my $name = shift;
        if (Haver::Util::is_valid_name($name)) {
            return $self->{name} = $name;
        } else {
            croak "Can't set name to invalid value of $name!";
        }
    }
}


sub load {
    my ($this, $data) = @_;
    my $self = $this->new;
    $self->name($data->{name});
    $self->attr($data->{attr});
    return $self;
}

sub dump {
    my ($self) = @_;
    return {
        name => $self->name,
        attr => $self->attr,
    };
}


1;
