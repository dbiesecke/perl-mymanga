###########################################
  package MyManga::httpd;
  use strict;
  use warnings;
  use Log::Log4perl qw(:easy);
  use AnyEvent;
  use AnyEvent::HTTPD;
  use JSON qw( to_json );
  use File::Temp qw( tempfile );
  use MooseX::App::Command; # important
  use App::Daemon qw( daemonize );

  extends qw(MyManga); # purely optional, only if you want to use global options from base class
  

  
  option 'private_balance' => (
      is            => 'rw',
      isa           => 'Bool',
      default       => 1,
      documentation => q[Disable private balance],
  ); # Option


sub run {
   my ($self,@arr) = @_;
#daemonize();
my $nmap = MyManga::httpd->new();

$nmap->start();

my $cv = AnyEvent->condvar();
$cv->recv();

}

###########################################
sub new {
###########################################
  my( $class, %options ) = @_;

  my( $fh, $tmp_file ) = 
     tempfile( UNLINK => 1 );

  my $self = {
    fork       => undef,
    json       => "",
    child      => undef,
    scan_range => [],
    %options,
  };

  bless $self, $class;
}


###########################################
sub start {
###########################################
  my( $self ) = @_;

  $self->{ timer } = AnyEvent->timer(
    after    => 0, 
    interval => 3600, 
    cb => sub { 
      if( defined $self->{ fork } ) {
          DEBUG "nmap already running";
          return 1;
      }
      $self->nmap_spawn();
    },
  );

  $self->httpd_spawn();
}

###########################################
sub nmap_spawn {
###########################################
  my( $self ) = @_;

  $self->{ fork } = fork();

  if( !defined $self->{ fork } ) {
    LOGDIE "Waaaah, failed to fork!";
  }

  if( $self->{ fork } ) {
      # parent
    $self->{ child } = AnyEvent->child( 
      pid => $self->{ fork }, 
      cb  => sub {
#         $self->{ json } = MyManga::kraken::run();
        $self->{ fork } = undef;
      } );
  } else {
      # child
#     $self->{ json } = MyManga::kraken::run();
    #exec "uname","-a",'>/tmp/tmp.1.log'
  }
}

###########################################
sub httpd_spawn {
###########################################
  my( $self ) = @_;

  $self->{ httpd } = 
    AnyEvent::HTTPD->new( port => 9090 );

  $self->{ httpd }->reg_cb (
    '/' => sub {
      my ($httpd, $req) = @_;

      $req->respond({ content => 
        ['text/json', $self->{ json } ],
      });
    },
  );
}

1;
