#!/usr/bin/perl -w
use strict;
use File::Spec;

use Test::More tests => 4;
use Test::Differences;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

{
    my $first_body = read_file( 'msgs_01.txt' );
    my $reform = $w->reformat_headers( $first_body );
    my $reform_file = read_file( 'msgs_01re.txt' );
    eq_or_diff ($reform => $reform_file, 'Reformatted message headers');
}

pass("All done");

sub read_file {
    my $file = shift;
    $file = File::Spec->catfile( 't', $file ) if -d 't';
    open my $fh, '<', $file or die $!;
    my $rv;
    read( $fh, $rv, -s $fh );
    $rv;
}
