# Haver::Server - The Server class.
# 
# Copyright (C) 2003-2004 Dylan William Hardison
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
package Haver::Server;
use strict;
#use warnings;

our %Feature;
our $Config;
our $Registry;
our $VERSION = 0.051;
BEGIN {
	use open ":utf8";
	use Exporter;
	use base 'Exporter';

	our $RELOAD  = 1;
	our @EXPORT = ();
	our @EXPORT_OK = qw( $Registry $Config %Feature );
}

use IO::Poll;
use POE;
use Haver::Server::Listener;
use Haver::Server::Registry;
use Haver::Server::Channel;
use Haver::Server::User;

use Haver::Config;
use Haver::Utils::Logger;
use Haver::Protocol::Filter;
use Haver::Reload;

sub boot {
	my ($this, %opts) = @_;
	$|++;


	eval {
		require  POE::Component::IKC::Server;
		import  POE::Component::IKC::Server;
	};
	unless ($@) {
		create_ikc_server(
			ip    => 'localhost', 
			port  => 4040,
			name  => 'Haver'
		);
		$Feature{IKC} = 1;
	}
	

	Haver::Reload->init;
	Haver::Protocol::Errors->server_mode();
	$Config   = new Haver::Config(file => $opts{config});
	$Registry = instance Haver::Server::Registry;

	foreach my $cid (@{ $Config->{Channels} }) {
		my $chan = new Haver::Server::Channel(id => $cid);
		eval { $chan->load };
		if ($@) {
			warn "Can't load $cid.\n$@";
		}
		$Registry->add($chan);
	}

	
	$this->create(%opts);
	$poe_kernel->run();
}
sub create {
	my ($class, %opts) = @_;
	POE::Session->create(
		package_states => [
			$class => [
				'_start',
				'_stop',
				'interrupt',
				'die',
				'shutdown',
			]
		],
		heap => \%opts,
	);
}

sub _start {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	my $port = $heap->{port} || $Config->{ServerPort} || 7070;
	
	print "Server starts.\n";
	create Haver::Utils::Logger    (logfile => $heap->{logfile} || '-');
	create Haver::Server::Listener (port => $port);

	$kernel->sig('INT' => 'intterrupt');
	$kernel->sig('DIE' => 'die');
}
sub _stop {
	print "Server stops.\n";

	$Config->{Channels} = $Registry->list_ids('channel');

	foreach my $chan ($Registry->list_vals('channel')) {
		eval { $chan->save };
		if ($@) {
			warn "Can't save ".$chan->id.":\n$@";
		}
	}
}

sub die {
}

sub interrupt {
	print "Got INT\n";
}
sub shutdown {
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Haver::Server - Haver chat server.

=head1 SYNOPSIS

  use Haver::Server;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Haver::Server, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Dylan William Hardison, E<lt>dylanwh@tampabay.rr.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2004 by Dylan William Hardison

This module is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this module; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
