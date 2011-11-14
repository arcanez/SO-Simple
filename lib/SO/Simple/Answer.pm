package SO::Simple::Answer;
use Moose;
use DateTime;
use Digest::SHA qw(sha1_hex);

has id => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub { sha1_hex( shift->text ) }
);

has text => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has author => (
    isa      => 'SO::Simple::User',
    is       => 'ro',
    required => 1,
);

has votes => (
    isa     => 'ArrayRef[SO::Simple::User]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        votes       => 'elements',
        votes_count => 'count',
    }
);

has timestamp => (
    isa     => 'DateTime',
    is      => 'ro',
    default => sub { DateTime->now }
);

1;
