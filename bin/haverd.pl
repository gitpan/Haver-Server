#!/usr/bin/perl
# haverd.pl, This is a haver-compatible server.
# This really doesn't do much, except load a few modules and start everything.
# Copyright (C) 2003 Dylan William Hardison
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#iiiiiii
use strict;
use warnings;
$|++;
#sub POE::Kernel::TRACE_REFCNT () { 1 }
use POE;
use Haver::Server::Listener ;
use Haver::Utils::Logger;
use Haver::Server::Registry;

my $Registry = instance Haver::Server::Registry;
$Registry->add_channel(
	new Haver::Server::Channel(cid => 'lobby')
);
for (1 .. 5) {
	$Registry->add_channel(
		new Haver::Server::Channel(cid => "spoon-$_")
	);
}


create Haver::Utils::Logger ;
create Haver::Server::Listener (shift || 7070);


$poe_kernel->run();
