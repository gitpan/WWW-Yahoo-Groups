#!/usr/bin/perl -w
use strict;
use Build;

my @extra_requires;
my @extra_build;

eval { require Module::Signature };
push @extra_build, "Module::Signature" => '0.13' if !$@;

my $m = Build->new(
    dist_name => 'WWW-Yahoo-Groups',
    dist_version => '1.7.8',
    license => 'perl',

    requires => {
		'Locale::Maketext::Lexicon' => '0.24',
		'Params::Validate' => '0.58',
		'File::Spec' => '0.6',
		'Locale::Maketext' => '1.05',
		'Exception::Class' => '1.12',
		'HTML::Entities' => '1.25',
		'HTTP::Cookies' => '1.30',
		'File::Basename' => '2.4',
		@extra_requires,
	'perl'             => '5.6.0',
    },
    recommends => {
		'Test::Signature' => '1.03',
	    },
    build_requires => {
		'YAML' => '0.35',
		'Test::More' => '0.47',
		'Test::More'          => 0.47,
	'Test::Signature'     => 1.01,
	@extra_build,
    },

    verbose => 1,
);

$m->create_build_script;

1;
