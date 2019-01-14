#!/usr/bin/perl 
require Plugin::Tiny;
require Carp;
require Exporter;
require Moose;
require URI;
require WWW::Mechanize;

package MyManga::akumacorp;
  use WWW::Mechanize;
  use MooseX::App::Command; # important
  use File::Copy;
  use MyManga::mangacover;
  use Data::Dumper;
  use URI::Escape;
 use LWP::UserAgent;
  use Parallel::ForkManager;
  extends qw(MyManga); # purely optional, only if you want to use global options from base class
  

  parameter 'manga_titel' => (
      is            => 'rw',
      isa           => 'Str',
      documentation => q[Maximal Messages],
  ); # Option
  
  option 'kcc' => (
        is            => 'rw',
        isa           => 'Bool',
        default       => 1,
        documentation => q[ Use KCC to convert to MOBI ],
  ); # Option
  
  
  command_short_description q[ Manga-dl - Akuma Corp.];

  command_long_description q[ Downloaded anhand des Manga-Titels einen Titel von Akuma Corp ];
  
   
  sub run {
        my ($self,@arr) = @_;
      my $mech = WWW::Mechanize->new();
      my $manga = $self->{manga_titel} or die("error!");
      print "$manga\n";
      if ($manga =~/http:\/\//) {
            $mech->get($manga);
             downloadKap($mech,$manga);
            exit;
      }
      
      $mech->get('http://reader.akuma-corp.de/manga.php');
      
      print searchLinks($mech,$manga)."\t".getBook($mech)."\t".getChapter($mech)."\n";
      exit;
    #  mkdir(getTitle($mech),0777);
    #  chdir(getTitle($mech));
    #my $bla = MyManga::mangacover->new();
    #          $bla->searchManga(getTitle($mech));
    #my $uid = $bla->getUid;
    #  print "[X] ".getTitle($mech)." not found in MangaDB\n" if !($uid);
    #  while($mech){
    #    my $titel = getTitle($mech) or die("Error on getTitle!");
    #    #print "->$titel|\n";
    #    #search for manga in db ( add meta data)
    #    my $dirname = getTitle($mech)." Vol.".getBook($mech);
    #    if (-d "$dirname") {
    #        mkdir($dirname,0777) if( ($dirname) && (getTitle($mech)) && (getChapter($mech)) );        
    #        chdir($dirname);
    #        &getImage($mech);
    #        chdir("..");        
    #    }else {
    #        my $ready = getTitle($mech)." Vol.".(getBook($mech)-1) if (getBook($mech) > 1);
    #        print "[X] Volume:".getBook($mech)."...$ready\n";
    #        if (getBook($mech) > 1) {
    #            $self->makeMobi("$ready");
    #         system("comictagger.py -s -t cr -m \"series=$titel,issue=".getBook($mech)."\" -o -v \"$ready.cbz\"");
    #        }
    #                        
    #        mkdir($dirname,0777) if( ($dirname) && (getTitle($mech)) && (getChapter($mech)) );        
    #        chdir($dirname);
    #        &getImage($mech);
    #        chdir("..");             
    #    }
     #   
     #
     #
     #   #print getChapter($mech)."\t--".getTitle($mech)."\n";
     #   
     #   $mech->get(getNext($mech));
     #
     #}
  }
  
  #search mangapage for Manga and loop through all founds
  sub searchLinks {
      my $pm = Parallel::ForkManager->new(5);

      my $mech = shift;
      my ($search) = $_[0] or return; $search =~s/ /_/g;
        my $link_obj = $mech->find_all_links(url_regex => qr/serie=$search/i );
    DATA_LOOP:
        foreach(@{$link_obj}) {
        my $pid = $pm->start and next DATA_LOOP;
            printf( "%s\t%s\n\n", $_->text(), $_->url(),             );                
             #print Data::Dumper::Dumper($_)."\n";
             downloadKap($mech,$_->url());
        }
  }
  
  
  
  sub downloadKap {
      my $mech = shift;      my $count = "001";
      my $mechdl = WWW::Mechanize->new();
      my ($kapurl) = @_;
      $mech->get($kapurl);
      my $val =   $mech->find_image( url_regex => qr/Manga\// );
  #    return if (!($val));
      my $dirname =  getAlt($val->alt()) or die("error!");      
      
            mkdir($dirname,0777);
            chdir($dirname);       
      while($count != 0) { $count++;
            $mech->follow_link( text_regex => qr/>>/ )  or ( chdir("..") && return);
            my $val =   $mech->find_image( url_regex => qr/Manga\// );
      
            printf( "%s\t%s\n\n", getAlt($val->alt()), $val->url_abs());
            my $filename = getAlt($val->alt())."-$count.jpg";
                next if (-f $filename);
                $mechdl->get($val->url_abs()) or ( chdir("..") && return);
                $mechdl->save_content( "$filename", binmode => ':raw', decoded_by_headers => 1 );

                if (!($mech->find_link( text_regex => qr/>>/  ))) {
                    chdir("..");
                    return 1;
                    
                }                
      }
       chdir(".."); 
  }
  
  sub getAlt {
      my $text = shift;
      return if !($text);
      $text =~ s/Seite.+//ig;
    return $text;
  }

  sub getBook {
      my $mech = shift;
      my $uri = $mech->uri();
      return -1 if !($uri->as_string());
      #print "$1\n" if ($uri->as_string() =~ /Bd[\.]?(\d+)/i);
      return "$1" if ($uri->as_string() =~ /Bd[_\s]?(\d+)/ig);
      return "$1" if ($uri->as_string() =~ /Band[_\s]?(\d+)/ig);
      return "$1" if ($uri->as_string() =~ /Vol[._\s]?(\d+)/ig);
    return ;
  }
  
  sub getChapter {
      my $mech = shift;
      my $uri = $mech->uri();
      return -1 if !($uri->as_string());
      return ($1) if ( ($uri->as_string() =~ /Kapitel[\._\s]?(\d+)/ig) or ($uri->as_string() =~ /Kap[\._\s]?(\d+)/ig) );
      die("Error on getChapter ( Done?) !");
  }

  sub getPage {
      my $mech = shift;
      
      die("ERROR on ".$mech->title()."\n") if !($mech->title());
      return ($1) if ($mech->title() =~ /Page (\d+) /)
  }
    
  sub getTitle {
      my $mech = shift;
      return ($1) if (  ($mech->uri->as_string() =~ /serie=(.*)/ig) );

  }
  



1;