#!/usr/bin/perl 
require Plugin::Tiny;
require Carp;
require Exporter;
require Moose;
require URI;


package MyManga::kanjiku;
  use WWW::Mechanize;
  use URI::Escape;
  use Data::Dumper;
  use JSON;
  use URI::Escape;
  use LWP::Simple;
  use MooseX::App::Command; # important
  use Parallel::ForkManager;
  extends qw(MyManga); # purely optional, only if you want to use global options from base class
  

  option 'url' => (
      is            => 'rw',
      isa           => 'Int',
      documentation => q[Maximal Messages],
  ); # Option
  
  
  command_short_description q[ kanjiku];

  command_long_description q[ kanjiku desc  ];

  sub run {
      my ($self,@arr) = @_;
      my $manga = $self->{extra_argv}[0];
        print Data::Dumper::Dumper($self)."\n";
        my $mecha = WWW::Mechanize->new();
        $mecha->get("http://reader.kanjiku.net/");
        $mecha->set_visible('dbiesecke@gmail.com',"yeah12ha");
        $mecha->click();
        $mecha->get($manga);

      
        my $nextc = $1 if ($mecha->content =~/next_chapter = (.*)/i);
        die("EROR no next chapter!\n".$mecha->content()."\n") if !($nextc);
        my $files =  $1 if ($mecha->content =~/pages = (.*)/ig);
            my $str  = uri_unescape($files);
            $str =~ s/\\//g;
            $str =~ s/;$//g;
        my $dl = decode_json($str);
 
         #Create Major titeldir
         my $titel = getTitel($mecha);
            mkdir($titel,0777) if !( -d $titel);
            chdir($titel) if ( -d $titel );
         #Create Volume dir 
        my $volumetitel = getTitel($mecha).".v".getVolume($mecha->uri);
        mkdir($volumetitel,0777) if !( -d $volumetitel);
        chdir($volumetitel) if ( -d $volumetitel );
        
        print getChapter($mecha->uri)."\n";
        #print getVol($mecha->content)." ".getTitel($mecha)."\n";
        while ($mecha) {

            my $dl = decode_json($str);            
            print getVolume($mecha->uri)." ".getChapter($mecha->uri)."\n";
            my $vol = getVolume($mecha->uri);
            dlHash($mecha);
            my $url = nextChapter($mecha);
                 $mecha->get($url);
            if ($vol < getVolume($mecha->uri)) {

                chdir("..");
                system("kcc-c2e --profile=KFHD --format=MOBI --rotate --upscale  -m '".getTitel($mecha).".v$vol'");
                mkdir(getTitel($mecha).".v".getVolume($mecha->uri),0777);
                chdir(getTitel($mecha).".v".getVolume($mecha->uri));
            }
        }
      foreach(<./*.mobi>){ system("mycli mangatag \"$_\"")};
        #my $show_coins = $self->{coins} || '3';

      
  }
  
    sub getVolume {
        my ($uri) = @_;
        my $res = $1 if ($uri =~ /\/[\w]+\/(\d+)\//);
        return $res if ($res);
    }

    sub getChapter {
        my ($uri) = @_;
        return  $1 if ($uri =~ /\/[\w]+\/\d+\/(\d+)/);
    }    
    
    sub nextChapter {
        my ($mech) = @_;
        my $nextc = $1 if ($mech->content =~/next_chapter = "(.*)"/i);
        die("Last Chapter found!") if !($nextc);
        print "\t$nextc\n";
        return $nextc;
        
        
    }

    sub dlHash {
      my ($mech) = @_;
      my $pm = Parallel::ForkManager->new(10);
                my $files =  $1 if ($mech->content =~/pages = (.*)/ig);
                    my $str  = uri_unescape($files);
                    $str =~ s/\\//g;
                    $str =~ s/;$//g;
     my $hash = decode_json($str);                   
      my $titel = getTitel($mech)." v".getVolume($mech->uri)." c".getChapter($mech->uri);
      mkdir($titel,0777) if !( -d $titel);
      chdir($titel) if ( -d $titel );
    DATA_LOOP:
      foreach my $pic (@{$hash}) {
        my $pid = $pm->start and next DATA_LOOP;
            print $pic->{url}."\n";
            getstore($pic->{url},$pic->{filename});
        $pm->finish; # Terminates the child process
            
        }
    my $dir = getTitel($mech).".v".getVolume($mech->uri);
    system("zip -D \"../$dir.cbz\" *");
        
      chdir("..");
    }

    sub getVol {
        #Band1 Kapitel 1</a></h1>
        my ($content) = @_;
        my ($res,$title) = "";
        $res = $1 if ($content =~ m/>([\w\d\s\S. ]+)<\/a><\/h1>/ig);
        
        return $res     
    }
    sub getTitel {
        my ($mech) = @_;
        my $titel = $mech->title;
        $titel =~ s/ :: Kanjiku Manga Reader//;
        $titel =~ s/::.*//;
        chomp($titel);
        $titel =~ s/^ //;      $titel =~ s/ $//;        
        return $titel;
    }
  #  sub do_some { print "Hello World @_\n" }

1;
