#!/usr/bin/perl
# vim: set ft=perl:

use Test::More tests => 5;
use Haver::Server::Entity::Channel;
use Haver::Server::Entity::Lobby;

BEGIN { use_ok('Haver::Server::Entity::Lobby') };


my $chan = new Haver::Server::Entity::Channel (
	name => 'pants',
);
my $lobby = new Haver::Server::Entity::Lobby;
$lobby->add($chan);
my $data = $lobby->dump(new FakeStore);

is($data->{channels}[0], 'pants', "dumps lobby");

my $l2 = Haver::Server::Entity::Lobby->load($data, new FakeStore);
is_deeply($lobby, $l2, "loads lobby");

my $chan2 = $l2->get('channel', 'pants');
ok($chan2, "get works");

is($chan2->name, $chan->name, "name");

BEGIN {
	package FakeStore;
	use Spiffy -base;
	const exists => 1;
	sub fetch {
		my ($self, $ns, $name) = @_;
		new Haver::Server::Entity::Channel(name => $name);
	}

	sub insert { 1 }
}
