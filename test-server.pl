#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use Digest::SHA1 qw(sha1_base64);
use open ":utf8";
use charnames ':full';
my $socket = new IO::Socket::INET('localhost:7070');

use Haver::Protocol::Filter;
binmode $socket, ":utf8";
binmode STDOUT, ":utf8";

my $f = Haver::Protocol::Filter->new;
while ($_ = $socket->getline) {
	s/\r\n$//;
	print "$_\n";
	my ($cmd, @args) = split(/\t/, $_);
	if ($cmd eq 'WANT') {
		my $want = shift @args;
		if ($want eq 'VERSION') {
			say('VERSION', 'stupid');
		} elsif ($want eq 'UID') {
			say('UID', 'tester');
		} elsif ($want eq 'PASS') {
			my $hash = shift @args;
			say('PASS', sha1_base64(sha1_base64('password') . $hash));
		}
	} elsif ($cmd eq 'ACCEPT') {
		last;
	}
}

my $a = "Hi. \N{GREEK SMALL LETTER ALPHA}";

say('PMSG', 'tester', $a);
say('PMSG', 'dylan', $a);
say('JOIN', 'lobby');
say('MSG', 'lobby', "ESC: [\e] TAB: [\t] CR: [\n] LF: [\r]");


while ($_ = $socket->getline) {
	s/\r\n$//;
	my ($cmd, @args) = split(/\t/, $_);
	if ($cmd eq 'PMSG') {
		if ($args[1] eq $a) {
			print "OK!\n";
			last;
		} else {
			print "Bad! $args[1] ne $a\n";
		}
	}
}


sub say {
	print 'C: ', join("\t", @_), "\n";
	$socket->print($f->put([[@_]])->[0]);
}

