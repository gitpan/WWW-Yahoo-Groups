use Test::More tests => 10;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

# Our special user
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

# Fetch message 1 - a message with no attachment
{
    my $no_attach = eval
    {
	$w->fetch_message( 1 )
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
	fail("fetch 1 failed ".$@->error);
    } elsif ($@) {
	fail("fetch 1 failed, for some reason.");
	diag $@;
    } else {
	pass("fetch 1 succeeded.");
    }

    my $first_body = <<'EOF';
From www-yahoo-groups@perl.dellah.org Tue Oct 01 04:30:30 2002
Return-Path: <www-yahoo-groups@perl.dellah.org>
X-Sender: www-yahoo-groups@perl.dellah.org
X-Apparently-To: www_yaho_t@yahoogroups.com
Received: (EGP: mail-8_1_1_4); 1 Oct 2002 11:30:28 -0000
Received: (qmail 56362 invoked from network); 1 Oct 2002 11:30:28 -0000
Received: from unknown (66.218.66.218)
by m9.grp.scd.yahoo.com with QMQP; 1 Oct 2002 11:30:28 -0000
Received: from unknown (HELO ouroboros.anu.edu.au) (150.203.232.210)
by mta3.grp.scd.yahoo.com with SMTP; 1 Oct 2002 11:30:29 -0000
Received: (qmail 29678 invoked by uid 530); 1 Oct 2002 11:30:33 -0000
Date: Tue, 1 Oct 2002 21:30:32 +1000
To: www_yaho_t@yahoogroups.com
Subject: Test 1
Message-ID: <20021001113032.GI12853@ouroboros.anu.edu.au>
Mime-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
User-Agent: Mutt/1.5.1i
From: www-yahoo-groups@perl.dellah.org
X-Yahoo-Group-Post: member; u=126010992
X-Yahoo-Profile: perligain7ya5h00grrzogups

Test 1.

EOF

    is ($no_attach => $first_body, 'Retrieved message 1 correctly');
}

# Second message, with attachment
{
    my $attach = eval
    {
	$w->fetch_message( 2 )
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
	fail("fetch 2 failed ".$@->error);
    } elsif ($@) {
	fail("fetch 2 failed, for some reason.");
	diag $@;
    } else {
	pass("fetch 2 succeeded.");
    }

    my $second_body = <<'EOF';
From www-yahoo-groups@perl.dellah.org Tue Oct 01 04:34:24 2002
Return-Path: <www-yahoo-groups@perl.dellah.org>
X-Sender: www-yahoo-groups@perl.dellah.org
X-Apparently-To: www_yaho_t@yahoogroups.com
Received: (EGP: mail-8_1_1_4); 1 Oct 2002 11:34:24 -0000
Received: (qmail 66369 invoked from network); 1 Oct 2002 11:34:24 -0000
Received: from unknown (66.218.66.218)
by m2.grp.scd.yahoo.com with QMQP; 1 Oct 2002 11:34:24 -0000
Received: from unknown (HELO ouroboros.anu.edu.au) (150.203.232.210)
by mta3.grp.scd.yahoo.com with SMTP; 1 Oct 2002 11:34:23 -0000
Received: (qmail 29827 invoked by uid 530); 1 Oct 2002 11:34:27 -0000
Date: Tue, 1 Oct 2002 21:34:27 +1000
To: www_yaho_t@yahoogroups.com
Subject: Re: [www_yaho_t] Test 2
Message-ID: <20021001113427.GJ12853@ouroboros.anu.edu.au>
References: <20021001113032.GI12853@ouroboros.anu.edu.au>
Mime-Version: 1.0
Content-Type: multipart/signed; micalg=pgp-sha1;
protocol="application/pgp-signature"; boundary="eHhjakXzOLJAF9wJ"
Content-Disposition: inline
In-Reply-To: <20021001113032.GI12853@ouroboros.anu.edu.au>
User-Agent: Mutt/1.5.1i
From: www-yahoo-groups@perl.dellah.org
X-Yahoo-Group-Post: member; u=126010992
X-Yahoo-Profile: perligain7ya5h00grrzogups

--eHhjakXzOLJAF9wJ
Content-Type: multipart/mixed; boundary="mojUlQ0s9EVzWg2t"
Content-Disposition: inline

--mojUlQ0s9EVzWg2t
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline

* www-yahoo-groups@perl.dellah.org (www-yahoo-groups@perl.dellah.org) [01 Oct 2002 21:31]:
> Test 2.

An attachment!

--mojUlQ0s9EVzWg2t
Content-Type: text/plain; charset=us-ascii
Content-Disposition: attachment; filename=perlupd

#!/bin/sh
rsync --delete -avz rsync://ftp.linux.activestate.com/perl-current/ bleadperl/

--mojUlQ0s9EVzWg2t--

--eHhjakXzOLJAF9wJ
Content-Type: application/pgp-signature
Content-Disposition: inline

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.0.7 (GNU/Linux)

iD8DBQE9mYhCzL8gm6KQWMgRAktEAJ9cLSGQduSi+cea8dJ79tlPl30m8gCgiwKA
hYNlSCsO1kPwmOUTPp/x1Fg=
=tt8E
-----END PGP SIGNATURE-----

--eHhjakXzOLJAF9wJ--

EOF

    is ($attach => $second_body, 'Retrieved message 2 correctly');
}

# Third message, non-existent
{
    my $attach = eval
    {
	$w->fetch_message( 242390 )
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::NotThere')) {
	pass("fetch 3 failed ".$@->error);
    } elsif ($@) {
	fail("fetch 3 failed, for some reason.");
	diag $@;
    } else {
	fail("fetch 3 succeeded. Should not have");
    }
}


pass("All done");
exit(0);
