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

#use POE::Preprocessor;
use base 'Haver::Server::Object';

our $VERSION = "0.001";
our $UID = 1;


sub initialize {
	my ($me) = @_;

	$me->{uid}      ||= 'user'.$UID++;
	$me->{cid_list}   = {};
	croak "session id (sid) required!" unless $me->{sid};
	
	$POE::Kernel::poe_kernel->refcount_increment($me->{sid}, __PACKAGE__);
}

sub finalize {
	my ($me) = @_;
	$POE::Kernel::poe_kernel->refcount_decrement($me->{sid}, __PACKAGE__);
}

sub uid {
	return $_[0]{uid};
}

#use Data::Dumper;
sub send {
	my ($me, @msgs) = @_;

	#print "-- msg --\n";
	#print Dumper($msgs[0]);
	#print "-- end --\n";
	
	
	$POE::Kernel::poe_kernel->post($me->{sid}, 'send', @msgs);
}

sub subscribe {
	my ($me, $chan) = @_;

	unless ($me->is_subscribed($chan->cid)) {
		$me->{cid_list}{$chan->cid} = $chan;
	} else {
		return undef;
	}
}

sub unsubscribe {
	my ($me, $chan) = @_;
	my $cid = ref $chan ? $chan->cid : $chan;

	delete $me->{cid_list}{$cid};
}

sub is_subscribed {
	my ($me, $chan) = @_;
	my $cid = ref $chan ? $chan->cid : $chan;

	return exists $me->{cid_list}{$cid};
}

sub subscriptions_by_val {
	my ($me) = @_;
	my $h = $me->{cid_list};

	return wantarray ? values %{ $h } : [ values %{ $h } ];
}

sub subscriptions_by_id {
	my ($me) = @_;
	my $h = $me->{cid_list};

	return wantarray ? keys %{ $h } : [ keys %{ $h } ];
}

1;

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


