package SO::Simple;
use Web::Simple 'SO::Simple';
use HTML::Zoom;
use Plack::Builder;
use SO::Simple::Model;
use SO::Simple::Page;

with 'SO::Simple::Sugar';

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

has page => (
  is => 'ro',
  lazy => 1,
  builder => '_build_page',
  handles => [ qw(apply_template render_to_fh) ],
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

sub _build_page {
  my $self = shift;
  SO::Simple::Page->new( template_dir => $self->template_dir );
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
    $_[0]->status_ok($_[0]->apply_template('index')->render_to_fh);
  },

  sub (GET + /question/new) {
    $_[0]->status_ok($_[0]->apply_template('new_question')->render_to_fh);
  },

  sub (POST + /question/new/ + %title=&text=) {
    my ($self, $title, $text) = @_;
    my $env = $_[PSGI_ENV];
    my $session = $env->{'psgix.session'};
    try {
      my $dir = $self->kioku;
      my $scope = $dir->new_scope;
      my $user = $dir->lookup( 'user:' . $session->{user}->id );
      my $question = SO::Simple::Question->new(
        author => $user,
        title  => $title,
        text   => $text,
      );
        $dir->store($question);
        $self->redirect_to('/question/' . $question->id);
    }
    catch {
#        debug $_;
#        template 'new_question' => { error => $_ };
    }
  },

  sub (GET + /question/*) {
    my ($self, $id) = @_;

    my $dir = $self->kioku;
    my $scope = $dir->new_scope;
    my $question = $dir->lookup( $id );
    $self->status_ok($self->apply_template('question')->render_to_fh);
  },

  sub (POST + /question/*/answer + %text=) {
    my ($self, $id, $text) = @_;
    $self->redirect_to('/question/' . $id);
  },

  sub (GET + /login) {
    $_[0]->status_ok($_[0]->apply_template('login')->render_to_fh);
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
    $self->redirect_to('/');
  },

  sub (GET + /logout) {
    my $self = shift;
    delete $_[PSGI_ENV]->{'psgix.session'}{$_} for keys %{$_[PSGI_ENV]->{'psgix.session'}};
    $self->_clear_session;
    $self->redirect_to('/');
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
