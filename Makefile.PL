use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'WWW::Yahoo::Groups',
    VERSION_FROM	=> 'lib/WWW/Yahoo/Groups.pm',
    PREREQ_PM => {
		'WWW::Mechanize' => '0.51',
		'Params::Validate' => '0.62',
		'IO::Socket::SSL' => '0.94',
		'Exception::Class' => '1.13',
		'HTML::Entities' => '1.25',
		'HTTP::Cookies' => '1.30',
		'Test::More' => '0.47',
	    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/WWW/Yahoo/Groups.pm',
      AUTHOR     => 'Iain Truskett <spoon@cpan.org>') : ()),
    ( eval($ExtUtils::MakeMaker::VERSION) >= 6.10 ?
	( NO_META => 1, ) : ()),
);
