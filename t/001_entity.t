#!/usr/bin/perl
# vim: set ft=perl:

use Test::More tests => 5;
BEGIN { 
    use_ok('Haver::Server::Entity');
};

my $ent = new Haver::Server::Entity (
	name  => 'thing',
	attr  => {
		foo => "bar",
		bar => "baz",
		baz => "quux",
	},
);

ok($ent, "avatar object created");

eval {
	$ent->name("####INVALIDNAME^^^");
};
if ($@) {
	pass("Can't set name to bad thing");
} else {
	fail("Set name to bad thing. This is bad");
}
is($ent->name, 'thing', "Is the name the same?");

my $data = $ent->dump;
my $ent2 = Haver::Server::Entity->load($data);
is_deeply($ent, $ent2, "saving and loading works");

