package SO::Simple::Sugar;
use Moo::Role;

sub status_ok {
  $_[1] = ref($_[1]) eq 'HTML::Zoom::ReadFH' ? $_[1] : [ $_[1] ];
  [ 200, [ 'Content-type' => 'text/html' ], $_[1] ] 

}

sub redirect_to {
  [ 302, [ Location => $_[1] ], [] ]
}

1;
