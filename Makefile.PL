use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Yahoo::Groups',
    'VERSION'	=> '1.1', # finds $VERSION
    'PREREQ_PM'		=> {
	'WWW::Mechanize' => 0.31,
	'HTTP::Cookies'  => 1.24,
	'HTML::Entities' => 1.23,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( AUTHOR     => 'Iain Truskett <spoon@cpan.org>') : ()),
);
