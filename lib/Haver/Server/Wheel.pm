# vim: set ts=4 sw=4 noexpandtab si ai sta tw=100:
# This module is copyrighted, see end of file for details.
package Haver::Server::Wheel;
use strict;
use warnings;
use Haver::Wheel -base;
use Haver::Logger 'Log';

our $VERSION     = 0.04;
our @EXPORT_BASE = 'Log';

sub msg {
	my $self = shift;

	foreach my $word (@_) {
		my $method = "msg_$word";
		$method =~ s/\W/_/g;
		$self->provide("msg_$word", $method);
	}
}


1;
