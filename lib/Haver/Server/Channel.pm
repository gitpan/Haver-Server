package Haver::Server::Channel;
use strict;
use warnings;

use Haver::Server::Object::Container;
use base ('Haver::Server::Object::Container');

our $VERSION = '0.02';

sub namespace {
	return 'channel';
}
sub can_contain {
	my ($me, $obj) = @_;
	
	!$obj->isa(__PACKAGE__);
}
sub send {
	my $me = shift;

	foreach my $user ($me->list_vals('user')) {
		$user->send(@_);
	}
}


1;
