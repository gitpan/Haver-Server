#!/usr/bin/perl

use strict;
use warnings;

my $file = 'haverd.yml';
my $sdir = './store';

make_config_file($file) unless -e $file;
make_store_dir($sdir) unless -d $sdir;


sub make_store_dir {
	my $dir = shift;
	print "Making store dir: $dir\n";
	mkdir($dir) or die "Can't mkdir($dir): $!";
}

sub make_config_file {
	my $file = shift;
	print "Making config file for server: $file\n";

	open my $fh, ">$file" or die "Can't open $file for writing: $!";
	print $fh <<YAML;
--- #YAML:1.0
Channels:
  - lobby
PingTime: 60
ServerPort: 7070
StoreDir: './store'
YAML
	close $file;
}


