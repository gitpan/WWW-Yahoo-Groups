use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'WWW::Yahoo::Groups',
    VERSION_FROM        => 'lib/WWW/Yahoo/Groups.pm',
    PREREQ_PM => {
                'Exception::Class' => '1.14',
                'HTML::Entities' => '1.26',
                'HTTP::Cookies' => '1.30',
                'Net::SSL' => '2.77',
                'Params::Validate' => '0.65',
                'WWW::Mechanize' => '0.57',
                'Test::Differences' => '0.47',
                'Test::More' => '0.47',
            },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/WWW/Yahoo/Groups.pm',
      AUTHOR     => 'Iain Truskett <spoon@cpan.org>') : ()),
    ( eval($ExtUtils::MakeMaker::VERSION) >= 6.10 ?
        ( NO_META => 1, ) : ()),
);
