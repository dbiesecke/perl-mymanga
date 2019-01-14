#!/usr/bin/perl 
require Plugin::Tiny;
require Carp;
require Exporter;
require Moose;
require URI;
require WWW::Mechanize;

package MyManga::wiemanga;
  use WWW::Mechanize;
  use MooseX::App::Command; # important
  use File::Copy;
  use MyManga::mangacover;
  extends qw(MyManga); # purely optional, only if you want to use global options from base class
  

  option 'url' => (
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
  
  
  command_short_description q[ wiemanga];

  command_long_description q[ wiemanga desc  ];
  
   
  sub run {
        my ($self,@arr) = @_;
      my $mech = WWW::Mechanize->new();
      my @args = $self->{extra_argv};
      $mech->get($self->{extra_argv}[0]);
      mkdir(getTitle($mech),0777);
      chdir(getTitle($mech));
    my $bla = MyManga::mangacover->new();
              $bla->searchManga(getTitle($mech));
    my $uid = $bla->getUid;
      print "[X] ".getTitle($mech)." not found in MangaDB\n" if !($uid);
      while($mech){
        my $titel = getTitle($mech) or die("Error on getTitle!");
        #print "->$titel|\n";
        #search for manga in db ( add meta data)
        my $dirname = getTitle($mech)." Vol.".getBook($mech);
        if (-d "$dirname") {
            mkdir($dirname,0777) if( ($dirname) && (getTitle($mech)) && (getChapter($mech)) );        
            chdir($dirname);
            &getImage($mech);
            chdir("..");        
        }else {
            my $ready = getTitle($mech)." Vol.".(getBook($mech)-1) if (getBook($mech) > 1);
            print "[X] Volume:".getBook($mech)."...$ready\n";
            if (getBook($mech) > 1) {
                $self->makeMobi("$ready");
             system("comictagger.py -s -t cr -m \"series=$titel,issue=".getBook($mech)."\" -o -v \"$ready.cbz\"");
            }
                            
            mkdir($dirname,0777) if( ($dirname) && (getTitle($mech)) && (getChapter($mech)) );        
            chdir($dirname);
            &getImage($mech);
            chdir("..");             
        }
        


        #print getChapter($mech)."\t--".getTitle($mech)."\n";
        
        $mech->get(getNext($mech));
    
     }
  }
  
  sub makeMobi {
      my $self = shift;
      foreach my $dir (@_){
            next if not (-d $dir);
            system("kcc-c2e --profile=KFHD --format=MOBI --rotate --upscale  -m \"$dir\" >/dev/null 2>/dev/null") if ($self->{kcc});
            system("mycli mangatag \"$dir.mobi\"");
            system("cd \"$dir\" && zip -D \"../$dir.cbz\" *");
            system("rmdir -fR \"$dir\"");
      }
  }
  
  sub getNext {
      my $mech = shift;
      return if !($mech->content());
      return $1 if ($mech->content() =~ /next_page = "(.*)"/);

  }

  sub getBook {
      my $mech = shift;
      my $uri = $mech->uri();
      return -1 if !($uri->as_string());
      #print "$1\n" if ($uri->as_string() =~ /Bd[\.]?(\d+)/i);
      return "$1" if ($uri->as_string() =~ /Bd[.+]?(\d+)/ig);
      return "$1" if ($uri->as_string() =~ /Band[.+]?(\d+)/ig);
    return -1;
  }
  
  sub getChapter {
      my $mech = shift;
      my $uri = $mech->uri();
      return -1 if !($uri->as_string());
      return ($1) if ($uri->as_string() =~ /Kapitel[.+]?(\d+)/ig);
      return ($1) if ($uri->as_string() =~ /Kap[.+]?(\d+)/ig);
      die("Error on getChapter ( Done?) !");
  }

  sub getPage {
      my $mech = shift;
      
      die("ERROR on ".$mech->title()."\n") if !($mech->title());
      return ($1) if ($mech->title() =~ /Page (\d+) /)
  }
    
  sub getTitle {
      my $mech = shift;
      return if !($mech->title());
      return ($1) if ($mech->title() =~ /Page \d+ (.+) manga auf deutsch/)
  }
  
  sub getImage {
      my $mech = shift;
      my $plus1 = 0;
      my $page =  getPage($mech);
      my $chap =  getChapter($mech);
      my $book =  getBook($mech);
            mkdir($page,0777);
            chdir($page); 
        foreach($mech->find_image( url_regex => qr/wiemanga.com.+_0.jpg$/, alt_regex => qr/\w/i)){
                    $plus1++;
                    system("wget -x -O c".$chap."-".$page."_0.jpg -q ".$_->{url}." ");
        }
        foreach($mech->find_image( url_regex => qr/wiemanga.com.+_1.jpg$/, alt_regex => qr/\w/i)){
                    system("wget -x -O c".$chap."-".$page."_1.jpg -q ".$_->{url}." ");
                    $plus1++;
        }
        print "[".$page."/$plus1]".$book."-".$chap."\n";
        chdir("..");
        system("kcc-c2p -y 800 -m $page >/dev/null 2>/dev/null") if ( $plus1 > 1);
        system("mv ./$page-Splitted/* . && rm -fR ./$page-Splitted ./$page") if ( $plus1 > 1);
        system("mv ./$page/*.jpg . && rm -fR ./$page") if ( $plus1 == 1);

        
        
  }


1;