#!/usr/bin/perl 
require Plugin::Tiny;
require Carp;
require Exporter;
require Moose;
require URI;


package MyManga::json;
  use Data::Dumper qw(Dumper);
  use JSON (from_json);
  use MooseX::App::Command; # important
  extends qw(MyManga); # purely optional, only if you want to use global options from base class
  

#   parameter 'file' => (
#       is            => 'rw',
#       isa           => 'Str',
#       documentation => q[Text/Json file content],
#   ); # Option
#   
  
  command_short_description q[ convert text to json];

  command_long_description q[  ];


our $VERSION = 0.02;

sub run {
    my ($self,@param) = @_;
    my $json = JSON::XS->new->allow_nonref;
#     my $self = bless { json => undef, args => $args }, $class;
      $self->{json} = ();
#     print $self->json_encode( @_ );
#   my $file = $self->{file};
    my @arr = ();
    my $count = 0;
    while(<STDIN>) {
    next if ($_ !~ /\{/g);
    $count++;
    my $input = $_;
    my $temp = $self->json_encode($input);
#     $self->{json}[$count] = $temp;
    my $ob = $json->decode($temp);
    print $temp."\n";
    # my $encode =  $self->json_encode($input)  ;
# my $bl$encode;
# push(@arr,$encode);
    }
#     my $encode = sub { $self->json_encode( @_ ) };
#     $context->define_vmethod( $_ => json => $encode ) for qw/hash list scalar/;
#     $context->define_filter( json => \&json_filter );
#     print $self->{json};
#     return $self;
}

sub json {
    my $self = shift;
    return $self->{json} if $self->{json};

    my $json = JSON->new->allow_nonref;
    my $args = $self->{args}; 
    for ( keys %$args ) {
        $json->$_( $args->{ $_ } ) if $json->can( $_ );
    }
    return $self->{json} = $json;
}

sub json_encode {
    my ($self, $value) = @_;
    json_filter( $self->json->encode( $value ) );
}

sub json_decode {
    my ($self, $value) = @_;
    $self->json->decode( $value );
}

sub json_filter {
    my $value = shift;
    $value =~ s!&!\\u0026!g;
    $value =~ s!<!\\u003c!g;
    $value =~ s!>!\\u003e!g;
    $value =~ s!\+!\\u002b!g;
    $value =~ s!\x{2028}!\\u2028!g;
    $value =~ s!\x{2029}!\\u2029!g;
    $value;
}

1;

__END__
=pod
=head1 NAME
Template::Plugin::JSON::Escape - Adds a .json vmethod and a json filter.
=head1 SYNOPSIS
    [% USE JSON.Escape( pretty => 1 ) %];
    <script type="text/javascript">
        var foo = [% foo.json %];
        var bar = [% json_string | json %]
    </script>
    or read in JSON
    [% USE JSON.Escape %]
    [% data = JSON.Escape.json_decode(json) %]
    [% data.thing %]
=head1 DESCRIPTION
This plugin allows you to embed JSON strings in HTML.  In the output, special characters such as C<E<lt>> and C<&> are escaped as C<\uxxxx> to prevent XSS attacks.
It also provides decoding function to keep compatibility with L<Template::Plugin::JSON>.
=head1 FEATURES
=head2 USE JSON.Escape
Any options on the USE line are passed through to the JSON object, much like L<JSON/to_json>.

  #  sub do_some { print "Hello World @_\n" }

1;
