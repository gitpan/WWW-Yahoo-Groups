#!/usr/bin/perl -w
use strict;
use File::Spec;
use blib;

use Test::More tests => 12;
use Test::Differences;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

{
    my %enc = (
        '210158114003056125033149109108' => 'ict@eh.org',
        '210166020185013028048218004077247130134058139051251019' => 'iain-yg@dellah.org',
        '196215254161050095074248017165225149068211139159132031047192'.
        '240003217076123176191121043188239199223163025167119111252040'.
        '233011227024073204157097255083229214' => '20030801122331.SQHR4342.fep08-svc.ttys.com@localhost',
        '06105623416517519021705001702815813107319222909302211620810008000319423'.
        '31242170550071621880340120851441211000302151902340131900880832261060190'.
        '74134142173139004212241202052031077123091049165235240216230234109192171'.
        '210036247207155003253065165' =>
            'sentto-4163449-682-1044260450-nerida_mills=yahoo.com.au@returns.groups.yahoo.com',
    );

    for my $enc ( sort { $enc{$a} cmp $enc{$b} } keys %enc )
    {
        my $wanted = $enc{$enc};
        my $dec = $w->decode_protected( $enc );
        is( $dec => $wanted, "Decode to $wanted" );
    }
}

{
    my $enc = '210158114003056125033139129148';
    my $wanted = 'ict@eh.org',
    my $dec = eval { $w->decode_protected( $enc ) };
    if ($@ and ref $@ and
        $@->isa('X::WWW::Yahoo::Groups::BadProtected'))
    {
        pass("Correctly failed parse");
    } elsif ($@) {
        fail("Failed unexpectedly: $@");
    } else {
        fail("Parse did not fail but was meant to");
    }
    isnt( $dec => $wanted, "Should not decode to $wanted" );
}

{
    my $wanted = read_file( 'msgs_12.txt' );

    $w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' );
    $w->list( 'Jade_Pagoda' );
    is($w->list() => 'Jade_Pagoda' => 'List set correctly.');

    my $msg = message( $w => 71674 );

    eq_or_diff ($msg => $wanted, 'Decoded message');

}

pass("All done");

sub message
{
    my ( $w, $id ) = @_;
    my $msg = eval
    {
	$w->fetch_message( $id )
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
	fail("Fetch $id failed ".$@->error);
    } elsif ($@) {
	fail("Fetch $id failed, for some reason.");
	diag $@;
    } else {
	pass("Fetch $id succeeded.");
    }

    return $msg;
}

sub read_file {
    my $file = shift;
    $file = File::Spec->catfile( 't', $file ) if -d 't';
    open my $fh, '<', $file or die $!;
    my $rv;
    read( $fh, $rv, -s $fh );
    $rv;
}
