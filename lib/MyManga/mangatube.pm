#!/usr/bin/perl 
require Plugin::Tiny;
require Carp;
require Exporter;
require Moose;
require URI;
require WWW::Mechanize;
require IO::Uncompress::Unzip;
require Archive::Zip;
require Data::Dumper;
require HTTP::Cookies;

package MyManga::mangatube;
  use WWW::Mechanize;
  use MooseX::App::Command; # important
  use File::Copy;
  use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
  use Archive::Zip;
  use Data::Dumper qw(Dumper);
  use HTTP::Cookies;
  use MyManga::mangacover;
  extends qw(MyManga); # purely optional, only if you want to use global options from base class
  

  parameter 'manga_short_name' => (
      is            => 'rw',
      isa           => 'Str',
      documentation => q[Manga short name like 100_sind_zu_wenig],
  ); # Option
  
  option 'dirs' => (
        is            => 'rw',
        isa           => 'Bool',
        default       => 1,
        documentation => q[ Put all files in current dir, default is in own directory ],
  ); # Option

  option 'kcc' => (
        is            => 'rw',
        isa           => 'Bool',
        default       => 1,
        documentation => q[ Use KCC to convert to MOBI ],
  ); # Option
  
  command_short_description q[! mangatube];

  command_long_description q[ !mangatube desc  ];
  
   
  sub run {
   my ($self,@arr) = @_;
      my $manga = $self->{manga_short_name} or die("error!");
      my $dir = $self->{dirs};
      my $kcc = $self->{kcc};
      my $return = {};

  
      
      my $mech = WWW::Mechanize->new();
      $mech->add_header( Encoding => 'utf-8' );
          $mech->get('http://www.manga-tube.org/reader/series/'.$manga.'/');

      my $titel = getTitle($mech);chomp($titel);  
      my @links = getLinks($mech);
      print "Titel:$titel|Downloads found:\t".@links."\n";

         my $bla = MyManga::mangacover->new();
                   $bla->searchManga($titel);
         my $uid = $bla->getUid;
         print "[X] $titel not found in MangaDB\n" if !($uid);
	     my $id = $bla->getMangaInfo;
	 my $rlsy = $bla->getReleaseYear || '1980';
        $bla->printInfo($id) if ($uid);
     # $titel = $bla->getTitel;
      # create dir "manga" if no other option selected  
      mkdir($titel,0777) if ($dir);
      chdir($titel) if ($dir);
      
      #my $front  = getCover($uid,$vol,"front");
      foreach my $url (@links){
            
            my $cdir = "./".$titel." Vol.".getBook($url) if ( (getBook($url) > 0) && ($dir));
            # create dir "<Manga>-Book<number>" if no other option selected  
            mkdir($cdir,0777) if ( (getBook($url) > 0) && ($dir));
            chdir($cdir) if ( (getBook($url) > 0) && ($dir));
            my ($filename);
            $filename = $manga." v".getBook($url)." ".getChapter($url).".cbz" if  (getBook($url) > 0);
            $filename = $manga." ".getChapter($url).".cbz"  if  (getBook($url) == 0);
            my $dirname = $manga." v".getBook($url)." ".getChapter($url);
            
            ( (print "Skipping $filename\n") and (next) )  if ( -d $dirname);
            print "Downloading\t$url\t$filename\n";
              $mech->get($url);
              $mech->save_content( "$filename", binmode => ':raw',
                         decoded_by_headers => 1 );
 #&& ($dir))
            unzipManga("$filename",$dirname);
            my $chap = getChapter($url);
            system("comictagger.py -s -t cr -m \"series=$titel,issue=$chap\" -o -v \"$filename\"");
            #system("comictagger.py -s -t cr -f  -o \"$filename\"");
            #system('mv "'.$filename.'" '.$titel.' v'.getBook($url).' '.getChapter($url).' (2000)');
              #Plastic Man v1 002 (1942).cbz
           chdir("..") if ( (getBook($url) > 0) && ($dir));
         
      }
      system("kcc-c2e --customwidth=800 --customheight=1280 --format=MOBI --rotate -m -q 2 --noprocessing --nocutpagenumbers *") if ($kcc);
      foreach(<./*.mobi>){ system("mycli mangatag \"$_\"")};
  }
  

sub getZipFileList(){
    my ($filename) = @_;
    my $zipobj = Archive::Zip->new()
       or die "Can't create zip object\n";
    if (my $error = $zipobj->read($filename) ) {
       die "Can't read $filename\n";
    }
    my @arr =  $zipobj->memberNames();
    return @arr;
 
}
  
sub unzipManga {
    my ($filename,$dir) = @_;
    #my $dir = 1;
    mkdir($dir,0777) if ($dir); 
 
    

    my $zip = Archive::Zip->new($filename);
    foreach my $member ($zip->members)
    {
        next if $member->isDirectory;
        (my $extractName = $member->fileName) =~ s{.*/}{};
        next if ( $extractName =~ /credits/ig);
        $member->extractToFileNamed(
          "$dir/$extractName");
    }

    #system("rm $filename");
            
}
  
  sub getLinks {
      my $mech = shift;
      my @arr = ();
      return if !($mech->content());
      my $content = $mech->content();
        while ( $content =~ m{(http://www.manga-tube.org/reader/download/[^" \t\n\r]+)}g ) {
            push(@arr,$1);
        }
      return @arr;
  }

  sub getBook {
      my $mech = shift;
      return ($1) if ( $mech =~ /\/de\/(\d+)\//ig);
      die("ERROR getBook on $mech\n");  
  }
  
  sub getChapter {
      my $mech = shift;
      return  if !( $mech =~ /\/de\/\d+\/(.*)\//ig);
      my $chaps = $1;
      $chaps =~ s/\//\./g;
      return $chaps;
  }

  sub getPage {
      my $mech = shift;
      
      die("ERROR on ".$mech->title()."\n") if !($mech->title());
      return ($1) if ($mech->title() =~ /Page (\d+) /)
  }
    
  sub getTitle {
      my $mech = shift;
      return if !($mech->title());
      die("Manga not found!") if ($mech->title() =~ /404/);
      my $titel = $1 if ($mech->title() =~ /(.*):: Manga-Tube/ig);
      return -1 if !($titel);
      chomp($titel);
      $titel =~ s/^ //;      $titel =~ s/ $//;
      return $titel;
  }
  
 

1;