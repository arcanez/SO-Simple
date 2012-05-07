package SO::Simple::User;
use Moose;
use DateTime;

with qw(KiokuX::User);

has timestamp => (
    isa     => 'DateTime',
    is      => 'ro',
    default => sub { DateTime->now }
);

has is_admin => (
    isa     => 'Bool',
    is      => 'rw',
    lazy    => 1,
    default => 0,
);

1;
