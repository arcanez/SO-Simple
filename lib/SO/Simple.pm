package SO::Simple;
use Web::Simple 'SO::Simple';
use HTML::Zoom;
use Plack::Builder;

has template_dir => (
  is => 'rw',
  default => sub { $_[0]->config->{template_dir} }
);

has zoom => (
  is => 'ro',
  default => sub {
    HTML::Zoom
    ->from_file($_[0]->template_dir . '/index.html')
    ->replace_content(title => $_[0]->config->{title})
    ->replace_content('#a_home' => $_[0]->config->{title})
  }
);

sub default_config {
  ( title => 'SO::Simple',
    template_dir => 'templates' );
}

sub dispatch_request {
  sub (/) {
    my $self = shift;
    my $content = 'STUFF HERE';
    my $fh = $self->zoom
             ->replace_content('div#main' => $content)
             ->to_fh;
    [ 200, [ 'Content-type' => 'text/html' ], $fh ]
  },

  sub (GET + /login) {
    my $self = shift;
    my @body;
    HTML::Zoom->from_file($self->template_dir . '/login.html')->select('div#main')->collect_content({ into => \@body })->run;
    my $fh = $self->zoom->replace_content('div#main' => \@body)->to_fh; 
    [ 200, [ 'Content-type' => 'text/html' ], $fh ]
  },

  sub (POST + /login + %username=&password=) {
    my ($self, $username, $password) = @_;
    [ 200, [ 'Content-type' => 'text/html' ], [ ] ]
  }
}

around to_psgi_app => sub {
  my $orig = shift;
  my $self = shift;
  my $app = $self->$orig(@_);
  builder {
    enable 'Plack::Middleware::Static',
      path => qr{^/(images|js|css)/}, root => 'static';
    $app;
  };
};

__PACKAGE__->to_psgi_app;
