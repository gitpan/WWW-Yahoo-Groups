#!/usr/bin/perl -w
use strict;
use Build;

my @extra_requires;
my @extra_build;

eval { require Module::Signature };
push @extra_build, "Module::Signature" => '0.13' if !$@;

my $m = Build->new(
    dist_name => 'WWW-Yahoo-Groups',
    dist_version => '1.8.1',
    license => 'perl',

    requires => {
	'Locale::Maketext::Lexicon' => '0.26',
	'Params::Validate' => '0.58',
	'Locale::Maketext' => '1.05',
	'Exception::Class' => '1.12',
	'HTML::Entities' => '1.25',
	'HTTP::Cookies' => '1.30',
	'Net::HTTPS' => '0.01',
	'IO::Socket::SSL' => '0.91',
	@extra_requires,
	'perl'             => '5.6.0',
    },
    recommends => {
	'Test::Pod' => '0.95',
	'File::Find::Rule' => '0.10',
	'Test::Signature' => '1.04',
    },
    build_requires => {
	'Test::More'          => 0.47,
	@extra_build,
    },
);

$m->create_build_script;

1;
