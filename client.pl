#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use Digest::SHA1 qw(sha1_base64);

my $socket = new IO::Socket::INET('localhost:7070');

while ($_ = $socket->getline) {
	s/\r\n$//;
	print "$_\n";
	my ($cmd, @args) = split(/\t/, $_);
	if ($cmd eq 'WANT') {
		my $want = shift @args;
		if ($want eq 'VERSION') {
			say('VERSION', 'stupid');
		} elsif ($want eq 'UID') {
			say('UID', 'dylan');
		} elsif ($want eq 'PASS') {
			my $hash = shift @args;
			say('PASS', sha1_base64(sha1_base64('bob') . $hash));
		}
	}
}

sub say {
	print join("\t", @_), "\n";
	$socket->print(join("\t", @_) . "\r\n");
}

