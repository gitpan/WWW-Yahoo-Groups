use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'WWW::Yahoo::Groups',
    VERSION_FROM        => 'lib/WWW/Yahoo/Groups.pm',
    PREREQ_PM => {
                'Params::Validate' => '0.64',
                'Exception::Class' => '1.14',
                'HTML::Entities' => '1.25',
                'HTTP::Cookies' => '1.30',
                'Test::More' => '0.47',
                'Test::Differences' => '0.47',
            },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/WWW/Yahoo/Groups.pm',
      AUTHOR     => 'Iain Truskett <spoon@cpan.org>') : ()),
    ( eval($ExtUtils::MakeMaker::VERSION) >= 6.10 ?
        ( NO_META => 1, ) : ()),
);
