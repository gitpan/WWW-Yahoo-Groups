use Test::More tests => 12;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );
isa_ok( $w => 'WWW::Mechanize' );

eval { $w->logout() };
if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::NotLoggedIn') ) {
    pass("Can not log out if not logged in.");
} elsif ($@) {
    fail("logout(): unexpected error: $@");
} else {
    fail("logout(): Expected error, did not receive one.");
}

for (1..2)
{
    eval { $w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' ) };
    ok (!$@, "Logged in");
    ok ($w->loggedin, "Am logged in");

    eval { $w->logout( ) };
    ok (!$@, "Logged out");
    ok (!$w->loggedin, "Am logged out");
}
