package WWW::Yahoo::Groups::Errors;
require Exception::Class;
use WWW::Yahoo::Groups::L10N;
our $lh = WWW::Yahoo::Groups::L10N->get_handle or die "Could not get localization handle!";

    Exception::Class->import(
	'X::WWW::Yahoo::Groups' => {
	    description => $lh->maketext('An error related to WWW::Yahoo::Groups'),
	    fields => [qw( fatal )],
	},
	'X::WWW::Yahoo::Groups::BadParam' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext('Invalid parameters specified for function'),
	},
	'X::WWW::Yahoo::Groups::BadLogin' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext('For some reason, your login failed'),
	},
	'X::WWW::Yahoo::Groups::NoHere' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext(
		"The ``here'' link was not found on the login page."),
	},
	'X::WWW::Yahoo::Groups::AlreadyLoggedIn' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext('You are already logged in with this object.'),
	},
	'X::WWW::Yahoo::Groups::NotLoggedIn' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext('You must be logged in to perform that method.'),
	},
	'X::WWW::Yahoo::Groups::NoListSet' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext('You tried accessing a method that required the list to be set'),
	},
	'X::WWW::Yahoo::Groups::UnexpectedPage' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext('We received a page that I do not understand'),
	},
	'X::WWW::Yahoo::Groups::NotThere' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext('The message you wanted is not in the archive'),
	},
	'X::WWW::Yahoo::Groups::BadFetch' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => $lh->maketext('We tried fetching a page, but failed'),
	},
    );

sub import
{
    my ($class) = @_;
    return (
	ignore_case => 1,
	strip_leading => 1,
	on_fail => sub {
	    chomp($_[0]);
	    X::WWW::Yahoo::Groups::BadParam->throw(error => $_[0], fatal => 1);
	}
    );
}
sub X::WWW::Yahoo::Groups::is_error { 1 }


1;
