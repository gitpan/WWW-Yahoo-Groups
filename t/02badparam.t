use Test::More tests => 21;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );
isa_ok( $w => 'WWW::Mechanize' );

# Things to test. These are all meant to fail.

my %subs = (
    login_named_dash => sub {
	$w->login(
	    -user => 'fnurdle',
	    -pass => 'gibberty'
	);
    },
    login_named => sub {
	$w->login(
	    user => 'fnurdle',
	    pass => 'gibberty'
	);
    },
    login_insufficient => sub { $w->login( 'fnurdle' ) },
    login_toomany => sub { $w->login( 'fnurdle', 'knud', 'grue' ) },
    login_arrayref => sub { $w->login( [ 'fnurdle' ], [ 'gibberty' ] ) },
    fetch_message_toomany => sub { $w->fetch_message( 2, 3 ) },
    fetch_message_string => sub { $w->fetch_message( 'fnurdle' ) },
    fetch_message_zero => sub { $w->fetch_message( 0 ) },
    fetch_message_undef => sub { $w->fetch_message( undef ) },
    list_blank => sub { $w->list( '' ) },
    list_toomany => sub { $w->list('fred', 'bob') },
    lists_toomany => sub { $w->lists( 5 ) },
    loggedin_toomany => sub { $w->loggedin( 5 ) },
    fetch_rss_toomany => sub { $w->fetch_rss( 2, 3 ) },
    fetch_rss_string => sub { $w->fetch_rss( 'fnurdle' ) },
    fetch_rss_zero => sub { $w->fetch_rss( 0 ) },
    fetch_rss_hundred_one => sub { $w->fetch_rss( 101 ) },
    fetch_rss_undef => sub { $w->fetch_rss( undef ) },
);

# Test that they all fail
# That is, it's a success if they fail and a failure if they succeeed.

foreach my $key (sort keys %subs)
{
    eval { $subs{$key}->() };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::BadParam')) {
	pass("$key: ".$@->error);
    } elsif ($@) {
	fail("$key: Failed, but not the right way.");
    } else {
	fail("$key: Did not fail, but was meant to.");
    }
}
