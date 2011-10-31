package SO::Simple;
use Web::Simple 'SO::Simple';
use HTML::Zoom;
use Plack::Builder;
use SO::Simple::Model;

has template_dir => (
  is => 'rw',
  lazy => 1,
  default => sub { $_[0]->config->{template_dir} }
);

has dsn => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->config->{dsn} }
);

has zoom => (
  is => 'ro',
  lazy => 1,
  builder => '_build_zoom',
  clearer => '_clear_zoom',
);

has session => (
  is => 'rw',
  lazy => 1,
  default => sub { +{} },
  clearer => '_clear_session',
);

has kioku => (
  is => 'ro', 
  lazy => 1,
  builder => '_build_kioku',
);

sub _build_zoom {
  my $self = shift;
  my $session = $self->session;
  my $rll = exists $session->{user} ?
            '<li><a href="/logout">Logout</a></li>' :
            '<li><a href="/login">Login</a></li>&nbsp;<li><a href="/register">Register</a></li>';

  HTML::Zoom
  ->from_file($self->template_dir . '/index.html')
  ->replace_content(title => $self->config->{title})
  ->replace_content('#a_home' => $self->config->{title})
  ->replace_content('ul#register_login_logout' => \$rll);
}

sub _build_kioku {
  my $self = shift;
  my $k = SO::Simple::Model->new(dsn => $self->dsn,
                                 extra_args => { create => 1 } ); 
}

sub default_config {
  ( title => 'SO::Simple',
    template_dir => 'templates',
    dsn => 'dbi:SQLite:so_simple.db' );
}

sub dispatch_request {
  sub (/) {
    my $self = shift;
    my $content = '';
    my $fh = $self->zoom
             ->replace_content('div#main' => $content)
             ->to_fh;
    [ 200, [ 'Content-type' => 'text/html' ], $fh ]
  },

  sub (GET + /login) {
    my $self = shift;
    my @body;

    HTML::Zoom
    ->from_file($self->template_dir . '/login.html')
    ->select('div#main')
    ->collect_content({ into => \@body })
    ->run;

    my $fh = $self->zoom->replace_content('div#main' => \@body)->to_fh; 
    [ 200, [ 'Content-type' => 'text/html' ], $fh ]
  },

  sub (POST + /login + %username=&password=) {
    my ($self, $username, $password) = @_;
    my $env = $_[PSGI_ENV];
    my $session = $env->{'psgix.session'};
    my $dir = $self->kioku;
    my $scope = $dir->new_scope;
    my $user = $dir->lookup('user:' . $username)
      or die 'Invalid username';
    $user->check_password($password)
      or die "Invalid password";
    $session->{user} = $username;
    $self->session($session);
    $self->_clear_zoom;
    [ 302, [ Location => '/' ], [] ];
  },

  sub (GET + /logout) {
    my $self = shift;
    delete $_[PSGI_ENV]->{'psgix.session'}{$_} for keys %{$_[PSGI_ENV]->{'psgix.session'}};
    $self->_clear_session;
    $self->_clear_zoom;
    [ 302, [ Location => '/' ], [] ];
  }
}

around to_psgi_app => sub {
  my $orig = shift;
  my $self = shift;
  my $app = $self->$orig(@_);
  builder {
    enable 'Static', path => qr{^/(images|js|css)/}, root => 'static';
    enable 'Session';
    $app;
  };
};

__PACKAGE__->to_psgi_app;
