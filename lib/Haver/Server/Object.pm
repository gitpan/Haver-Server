# Haver::Server::Object - OO Channel/User/etc base class.
# 
# Copyright (C) 2004 Dylan William Hardison
#
# This module is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This module is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this module; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package Haver::Server::Object;
use strict;
use warnings;
use Carp;

use Haver::Base;
use base 'Haver::Base';

our $VERSION = "0.001";

# XXX not used right now
#sub new {
#	my $me = shift->SUPER::new(@_);
#
#	# code goes here.
#
#	return $me;
#}

sub send { die "Must define send method!" }


sub set {
	my ($me, @set) = @_;
	
	while (my ($k,$v) = splice(@set, 0, 2)) {
		$me->{_fields}{$k} = $v;
	}
}

sub get {
	my ($me, @keys) = @_;

	if (@keys <= 1) {
		return $me->{_fields}{$keys[0]};
	}
	my @values;
	
	foreach my $key (@keys) {
		push(@values, $me->{_fields}{$key});
	}

	return wantarray ? @values : \@values ;
}

sub unset {
	my ($me, @keys) = @_;
	
	if (@keys <= 1) {
		return delete $me->{_fields}{$keys[0]};
	}
	my @values;
	
	foreach my $key (@keys) {
		push(@values, delete $me->{_fields}{$key});
	}
	
	return wantarray ? @values : \@values ;
}

sub keys : method {
	my ($me) = @_;
	return keys %{ $me->{_fields} };
}






1;

=head1 NAME

Haver::Server::Object - Base class for users and channels.
