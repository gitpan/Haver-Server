# Haver::Server::Registry - Index for users, channels, etc.
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

use Haver::Singleton;
use Haver::Server::Object::Index;

use base qw( Haver::Singleton Haver::Server::Object::Index );

our $VERSION = '0.02';

sub initialize {
	my ($me) = @_;
	$me->{id} = 'registry';
	
	# XXX Hello, I am a HACK! somebody please FIXME!
	Haver::Server::Object::Index->can('initialize')->(@_);
}
sub namespace {
	'registry';
}
sub filename {
	$Haver::Server::Object::DataDir . '/' . 'registry';
}


1;
