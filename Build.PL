#!/usr/bin/perl
require 5.008;
use Module::Build;
my $build = Module::Build->new(
	module_name        => 'Haver::Server',
	dist_author        => 'Dylan Hardison <dylan@haverdev.org>',
	license            => 'gpl',
	requires           => {
		'perl'            => '5.8.0',
		POE               => 0.27,
		'Digest::SHA1'    => 2.01,
		'Haver::Core'     => 0.08,
	},
	create_makefile_pl => 'passthrough',
	script_files => [glob('bin/*.pl')],
	# XXX: This is a hack, feel free to remove it...
	($ENV{USER} eq 'dylan') ? (sign => 1) : (),
);
$build->create_build_script();
