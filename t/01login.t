use Test::More tests => 5;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );
isa_ok( $w => 'WWW::Mechanize' );

eval {
    $w->login('fnurdle' => 'gibberty');
};
if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::BadLogin')) {
    pass("Login failed: ".$@->error);
} else {
    fail("Login succeeded, despite being meant to fail.");
}

eval {
    $w->fetch_message( 1 );
};
if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::NoListSet')) {
    pass("Fetch failed: ".$@->error);
} else {
    fail("Fetch succeeded, despite being meant to fail.");
}
