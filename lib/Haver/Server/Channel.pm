package Haver::Server::Channel;
use strict;
use warnings;

use Haver::Server;
use base     ('Haver::Server::Object');

our $VERSION = "0.001";

sub initialize {
	my ($me) = @_;

	die unless exists $me->{cid};

	$me->{userlist} = {};
}

sub cid {
	my ($me) = @_;

	return $me->{cid};
}

#use Data::Dumper;
sub send {
	my $me = shift;
	#print "-- c-msg --\n";
	#print Dumper($_[0]);
	#print "-- c-end --\n";


	foreach my $user ($me->userlist) {
		$user->send(@_);
	}
}


sub add {
	my ($me, $user) = @_;
	my $uid = $user->uid;
	
	unless ($me->contains($user)) {
		return $me->{userlist}{$uid} = $user;
	} else {
		return 0;
	}
}

sub remove {
	my ($me, $user) = @_;
	my $uid = ref $user ? $user->uid : $user;

	delete $me->{userlist}{$uid};
}

sub contains {
	my ($me, $user) = @_;
	my $uid = ref $user ? $user->uid : $user;

	return exists $me->{userlist}{$uid};
}


sub userlist {
	my ($me)  = @_;
	my @users = values %{ $me->{userlist} };

	return wantarray ? @users : \@users;
}

sub uidlist {
	my ($me)  = @_;
	my @users = keys %{ $me->{userlist} };

	return wantarray ? @users : \@users;
}

1;
