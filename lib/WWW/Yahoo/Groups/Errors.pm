package WWW::Yahoo::Groups::Errors;
our $VERSION = '1.87';
require Exception::Class;

    Exception::Class->import(
	'X::WWW::Yahoo::Groups' => {
	    description => 'An error related to WWW::Yahoo::Groups',
	    fields => [qw( fatal )],
	},
	'X::WWW::Yahoo::Groups::BadParam' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'Invalid parameters specified for function',
	},
	'X::WWW::Yahoo::Groups::BadLogin' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'For some reason, your login failed',
	},
	'X::WWW::Yahoo::Groups::NoHere' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => "The ``here'' link was not found on the login page.",
	},
	'X::WWW::Yahoo::Groups::AlreadyLoggedIn' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'You are already logged in with this object.',
	},
	'X::WWW::Yahoo::Groups::NotLoggedIn' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'You must be logged in to perform that method.',
	},
	'X::WWW::Yahoo::Groups::NoListSet' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'You tried accessing a method that required the list to be set',
	},
	'X::WWW::Yahoo::Groups::UnexpectedPage' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'We received a page that I do not understand',
	},
	'X::WWW::Yahoo::Groups::NotThere' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'The message you wanted is not in the archive',
	},
	'X::WWW::Yahoo::Groups::BadFetch' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'We tried fetching a page, but failed',
	},
        'X::WWW::Yahoo::Groups::BadProtected' => {
            isa => 'X::WWW::Yahoo::Groups',
            description => 'Protected string contains unknown control sequence. Table needs amending.',
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
