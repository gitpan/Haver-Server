#!/usr/bin/perl
# vim: set ft=perl:

use Test::More tests => 6;
BEGIN { 
    use_ok('Haver::Server::Entity::User');
    use_ok('Haver::Server::Entity::Channel');
};

my $user = new Haver::Server::Entity::User (
	name => 'bob',
);
my $chan = new Haver::Server::Entity::Channel (
	name => 'lobby',
);

ok($user, "user object created");
ok($chan, "channel object created");

$user->join($chan);
ok($chan->contains('user', $user->name), "user in channel");
$user->part($chan);
ok(not($chan->contains('user', $user->name)), "user not in channel");
