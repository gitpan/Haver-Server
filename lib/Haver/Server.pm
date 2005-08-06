# vim: set ft=perl ts=4 sw=4:
# Haver::Server - description
# 
# Copyright (C) 2005 Dylan Hardison.
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
use warnings;

use Haver::Session -base;
use Haver::Server::Listener;
use Haver::Server::Talker;
use Haver::Server::Entity::User;
use Haver::Server::Entity::Channel;
use Haver::Server::Entity::Lobby;
use Haver::Server::Config;
use Haver::Server::Store;

our $VERSION = 0.08;
our $Alias   = 'Server';
our $Config  = 'haverd.yml';

sub states {
	return [qw(
		_start _stop shutdown 
	)];
}

sub create {
	my $this = shift;
	Log('debug', "Booting Haver::Server v$VERSION");
	super;
}

sub _start {
	my ($kernel, $heap, $opt) = @_[KERNEL, HEAP, ARG0];
	$kernel->alias_set($Alias);
	Log('debug', "$Alias starts.");

	my $config = new Haver::Server::Config (
		load => $opt->{config} || $Config,
	);

	# Configure the Store.
	my $dir = $config->storedir;
	mkdir $dir or die "mkdir $dir: $!" unless -e $dir;
	my $store  = new Haver::Server::Store (
		storedir => $dir,
	);

	# Add &lobby to the Store if not already there.
	unless ($store->exists('lobby', '&lobby')) {
		Log('debug', 'Initializing &lobby');
		my $lobby = new Haver::Server::Entity::Lobby;
		$store->insert($lobby);
	}

	# Fetch the lobby
	Log('debug', "Fetching &lobby");
	my $lobby = $store->fetch('lobby', '&lobby');

	Log('debug', "Channels: ", join(", ", $lobby->names('channel')));
	
	create Haver::Server::Listener (
		config => $config,
		talker => sub {
			create Haver::Server::Talker(@_,
				lobby  => $lobby,
				config => $config,
				store  => $store,
			)
		}
	);

	$heap->{config} = $config;
	$heap->{store}  = $store;
	$heap->{lobby}  = $lobby;
}

sub _stop {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	Log('debug', "Saving config");
	$heap->{config}->save;
	Log('debug', "Storing &lobby");
	$heap->{store}->insert($heap->{lobby});
	
	Log('debug', "$Alias stops");
}

sub shutdown {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	$kernel->alias_remove($Alias);
}

1;

__END__

=head1 NAME

Haver::Server - Reference implementation of the Haver chat server.

=head1 SYNOPSIS

    use Haver::Server;
    create Haver::Server (
        config => 'haverd.yml',
    )
    POE::Kernel->run;
     
=head1 DESCRIPTION

FIXME

=head1 METHODS

There is only one method, create(), which is a class method.

=head2 create(alias => $alias, resolver => $resolver, version => $version)

This creates a new Haver::Client session. The only required parameter
is $alias, which is how you'll talk to the client session using L<POE::Kernel>'s post().

If given, $resolver should be a L<POE::Component::Client::DNS> object.

Finally, $version is what we will advertize as the client name and version number to the
server. It defaults to C<Haver::Client/0.08>.

=head1 STATES

While these are listed just like methods, you must post() to them, and not call them
directly.

=head2 connect(host => $host, name => $name, [ port => 7575 ])

Connect to $host on port $port (defaults to 7575) with the user name $name.
If already connected to a server, Haver::Client will disconnect and re-connect using the
new settings.

=head2 register(@events)

This summons the sun god Ra and makes him eat your liver.

FIXME: This is inaccurate.

=head1 BUGS

None known. Bug reports are welcome. Please use our bug tracker at
L<http://gna.org/bugs/?func=additem&group=haver>.

=head1 AUTHOR

Dylan Hardison E<lt>dylan@haverdev.orgE<gt>.

=head1 SEE ALSO

L<http://www.haverdev.org/>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Dylan Hardison. All Rights Reserved.

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

