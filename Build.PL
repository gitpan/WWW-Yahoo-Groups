#!/usr/bin/perl -w
use strict;
use Module::Build 0.11;

my $m = Module::Build->new(
    dist_name => 'WWW-Yahoo-Groups',
    dist_version => '1.4',
    license => 'perl',

    requires => {
	'WWW::Mechanize'   => 0.31,
	'HTTP::Cookies'    => 1.24,
	'Exception::Class' => 1.07,
	'Params::Validate' => 0.24,
	'HTML::Entities'   => 1.23,
	'Net::HTTPS'       => 0.01,
	'IO::Socket::SSL'  => 0.91,
	'perl'		   => '5.6.0',
    },
    build_requires => {
	'Test::More'       => 0.47,
    },
);

$m->create_build_script;
