#!/usr/bin/perl
use Module::Build;
my $build = Module::Build->new(
	module_name        => 'Haver::Server',
	dist_name          => 'haver-server',
	dist_version_from  => 'lib/Haver/Server.pm',
	dist_author        => 'Dylan William Hardison <dylanwh@tampabay.rr.com>',
	dist_abstract      => 'POE-based simple chat server',
	license            => 'gpl',
	requires           => {
		'perl'            => '5.6.1',
		POE               => 0.26,
		Haver             => 0.05,
		YAML              => 0.35,
		'Digest::SHA1'    => 2.01,
	},
	create_makefile_pl => 'passthrough',
	script_files => [glob('bin/*.pl')],
);

$build->create_build_script;

	

