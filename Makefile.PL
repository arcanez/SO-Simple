use ExtUtils::MakeMaker;
WriteMakefile(
    NAME      => 'SO::Simple',
    AUTHOR    => 'Justin Hunter <justin.d.hunter@gmail.com>',
    LICENSE => 'perl',
    VERSION_FROM => 'lib/SO/Simple.pm',
    ABSTRACT_FROM => 'lib/SO/Simple.pm',
    MIN_PERL_VERSION => '5.008001',
    PREREQ_PM => {
        'Web::Simple' => 0,
        'HTML::Zoom'  => 0,
    },
    BUILD_REQUIRES => {
	'Test::More' => 0,
    },
    META_MERGE      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/arcanez/SO-Simple/issues',
            repository  => 'https://github.com/arcanez/SO-Simple/'
        },
    },
);
