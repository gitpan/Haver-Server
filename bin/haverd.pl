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
use strict;
use warnings;
use lib qw( lib ../core/lib );
use POE;
use Haver::Server;

$|++;
create Haver::Server;
POE::Kernel->run;
