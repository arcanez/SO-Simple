package SO::Simple::Page;
use Moose;
use HTML::Zoom;

has template_dir => (
  is => 'ro',
  required => 1,
);

has zoom => (
  is => 'rw',
  lazy => 1,
  builder => '_build_zoom',
);

sub _build_zoom {
  my $self = shift;
  HTML::Zoom->from_file($self->template_dir . '/__base__.html');
}

sub apply_template {
  my ($self, $template) = @_;

  my @body;
  HTML::Zoom
  ->from_file($self->template_dir . '/' . $template . '.html')
  ->select('div#main')
  ->collect_content({ into => \@body })
  ->run;

  $self->zoom($self->zoom->replace_content('div#main', \@body));
  $self;
}

sub render_to_fh {
  $_[0]->zoom->to_fh;
}

__PACKAGE__->meta->make_immutable;
1;
