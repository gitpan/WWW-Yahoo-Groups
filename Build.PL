#!/usr/bin/perl -w
use strict;
use Build;

my @extra_requires;
my @extra_build;

eval { require Module::Signature };
push @extra_build, "Module::Signature" => '0.13' if !$@;

my $m = Build->new(
    dist_name => 'WWW-Yahoo-Groups',
    dist_version => '1.7.7',
    license => 'perl',

    requires => {
	'WWW::Mechanize'   => 0.31,
	'HTTP::Cookies'    => 1.24,
	'Exception::Class' => 1.07,
	'Params::Validate' => 0.24,
	'HTML::Entities'   => 1.23,
	'Net::HTTPS'       => 0.01,
	'IO::Socket::SSL'  => 0.91,
	@extra_requires,
	'perl'             => '5.6.0',
    },
    recommends => {
        'Locale::Maketext'          => '0.20',
        'Locale::Maketext::Lexicon' => '0.08',
	'YAML'			    => '0.35',
    },
    build_requires => {
	'Test::More'          => 0.47,
	'Test::Signature'     => 1.01,
	@extra_build,
    },

    verbose => 1,
);

$m->create_build_script;

1;
