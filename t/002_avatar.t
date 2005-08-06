#!/usr/bin/perl
# vim: set ft=perl:

use Test::More tests => 7;
BEGIN { 
    use_ok('Haver::Server::Entity::Avatar');
};

my $dummy = new DummyWheel;
my $ava = new Haver::Server::Entity::Avatar (
	name  => 'smith',
	wheel => $dummy,
);

ok($ava, "avatar object created");

$ava->grant('&lobby', 'kick', 10);
is($ava->may('&lobby', 'kick'), 10, "grant()/may()");
is($ava->revoke('&lobby', 'kick'), 10, "revoke()");
ok(!defined($ava->may('&lobby', 'kick')), "revoke()/may()");

$ava->put(['FOO', 'bar', 'baz']);
is_deeply(['FOO', 'bar', 'baz'], $dummy->msg, 'put()');

$ava->grant('&lobby', 'kick', 10);
my $data = $ava->dump;
my $ava2 = Haver::Server::Entity::Avatar->load($data);
is($ava->may('&lobby', 'kick'), $ava2->may('&lobby', 'kick'), "saving/loading ACLs");

BEGIN {
	package DummyWheel;
	sub new {
		return bless {};
	}
	sub put {
		my ($self, $msg) = @_;
		$self->{msg} = $msg;
	}
	sub msg { shift->{msg} }
}
