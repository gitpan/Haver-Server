# Haver::Server - The Server object.
# 
# Copyright (C) 2003 Dylan William Hardison
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

package Haver::Server::Registry;
use strict;
use warnings;

use Haver::Server::User;
use Haver::Server::Channel;
use Haver::Singleton;

use base 'Haver::Singleton';

our $VERSION = "0.001";

sub initialize {
	my ($me) = @_;
	$me->{users} = {};
	$me->{chans} = {};
}

sub add_user {
	my ($me, $user) = @_;
	my $uid = $user->uid;

	unless ($me->has_user($user)) {
		$me->{users}{$uid} = $user;
	} else {
		return undef;
	}
}

sub fetch_user {
	my ($me, $uid) = @_;
	return $me->{users}{$uid} if $me->has_user($uid);
}

sub has_user {
	my ($me, $user) = @_;
	my $uid = ref $user ? $user->uid : $user;
	
	exists $me->{users}{$uid};
}

sub remove_user {
	my ($me, $user) = @_;
	my $uid = ref $user ? $user->uid : $user;

	delete $me->{users}{$uid};
}

sub list_users_by_id {
	my ($me) = @_;
	my $h = $me->{users};

	wantarray ? keys %$h : [ keys %$h ];
}

sub list_users_by_val {
	my ($me) = @_;
	my $h = $me->{users};

	wantarray ? values %$h : [ values %$h ];
}

sub add_channel {
	my ($me, $chan) = @_;
	my $cid = $chan->cid;

	unless ($me->has_channel($chan)) {
		$me->{chans}{$cid} = $chan;
	} else {
		return undef;
	}
}

sub fetch_channel {
	my ($me, $cid) = @_;
	return $me->{chans}{$cid} if $me->has_channel($cid);
}

sub has_channel {
	my ($me, $chan) = @_;
	my $cid = ref $chan ? $chan->cid : $chan;
	
	exists $me->{chans}{$cid};
}

sub remove_channel {
	my ($me, $chan) = @_;
	my $cid = ref $chan ? $chan->cid : $chan;

	delete $me->{chans}{$cid};
}

sub list_channels_by_id {
	my ($me) = @_;
	my $h = $me->{chans};

	wantarray ? keys %$h : [ keys %$h ];
}

sub list_channels_by_val {
	my ($me) = @_;
	my $h = $me->{chans};

	wantarray ? values %$h : [ values %$h ];
}

1;
