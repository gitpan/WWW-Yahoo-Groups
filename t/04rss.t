use Test::More tests => 9;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );
isa_ok( $w => 'WWW::Mechanize' );

# Our special user, as usual
$w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' );

# Our special list
my $list = eval {
    $w->list( 'www_yaho_t' );
    return $w->list();
};
if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
    fail("Failed setting/getting list: ".$@->error);
} elsif ($@) {
    fail("Failed setting/getting list");;
} else {
    pass("Did not fail setting list.");
}
is($list => 'www_yaho_t' => 'List set correctly.');

# Get a supposedly valid RSS feed
{
    my $rsscontent = eval
    {
	$w->fetch_rss();
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
	fail("RSS fetch failed ".$@->error);
    } elsif ($@) {
	fail("RSS fetch failed, for some reason.");
	diag $@;
    } else {
	pass("RSS fetch succeeded.");
    }
}


# Try for a bad fetch
{
    # This list shouldn't exist
    my $list = eval {
	$w->list( 'www_yaho_txmg' );
	return $w->list();
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
	fail("Failed setting/getting list: ".$@->error);
    } elsif ($@) {
	fail("Failed setting/getting list");;
    } else {
	pass("Did not fail setting list.");
    }
    is($list => 'www_yaho_txmg' => 'List set correctly.');
    # Fetch RSS
    my $rsscontent = eval { $w->fetch_rss() };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::UnexpectedPage')) {
	pass("RSS fetch failed ".$@->error);
    } elsif ($@) {
	fail("RSS fetch failed, for some reason.");
	diag $@;
    } else {
	fail("RSS fetch succeeded.");
    }
}
