# Haver::Server::User - OO User object thing.
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
package Haver::Server::User;
use strict;
use warnings;
use Carp;


use Haver::Server::Object;
use Haver::Server::Object::Index;
use base qw( Haver::Server::Object Haver::Server::Object::Index );

our $VERSION = '0.03';

sub valid_uid {
	my ($this, $uid) = @_;

	if (defined $uid && $uid =~ /^[a-z][a-z0-9' _\.-]+$/) {
		return 1;
	} else {
		return 0;
	}
}

sub initialize {
	my ($me) = shift;

	$me->SUPER::initialize(@_);
	$POE::Kernel::poe_kernel->refcount_increment($me->{sid}, __PACKAGE__) if $me->{sid};
}
sub finalize {
	my ($me) = shift;
	$me->SUPER::finalize(@_);
	$POE::Kernel::poe_kernel->refcount_decrement($me->{sid}, __PACKAGE__) if $me->{sid};
}

sub on_save {
	my ($me, $save) = @_;
	if (exists $me->{password}) {
		$save->{password} = $me->{password};
	}
}
sub on_load {
	my ($me, $data) = @_;

	if (exists $data->{password}) {
		$me->{password} = $data->{password};
	}
}

sub namespace {
	'user'
}
sub send {
	my ($me, @msgs) = @_;
	$POE::Kernel::poe_kernel->post($me->{sid}, 'send', @msgs);
}

sub password {
	my ($me, $pass) = @_;

	unless (@_ == 2) {
		return $me->{password};
	} else {
		$me->{password} = $pass;
	}
}

sub sid {
	my ($me) = @_;
	return $me->{sid};
}

1;
__END__
=head1 NAME

Haver::Server::User - Object representation of a user.

=head1 SYNOPSIS

  use Haver::Server::User;
  my %opts = (); # No options at this time...
  my $uid  = 'rob';
  my $user = new Haver::Server::User($uid, %opts);
  
  $user->uid eq $uid; # True
  $user->set(nick => "Roberto");
  $user->set(away => "Roberto isn't here.");
  $user->get('nick') eq 'Roberto'; # True
  my ($nick, $away) = $user->get('nick', 'away'); # Obvious...
  my $array_ref = $user->get('nick', 'away'); # Like above, but a arrayref.

  $user->unset('nick', 'away'); # unset one or more items.

  my @fields = $user->keys; # Returns all fields.

  $user->add_cid($cid);
  $user->remove_cid($cid);

=head1 DESCRIPTION

This module is a representation of a user. It's rather pointless, but it gives
you a warm fuzzy feeling. In the future, it might store the users in a database or something.


