#!/usr/bin/perl 
require Plugin::Tiny;
require Carp;
require Exporter;
require Moose;
require URI;


package MyManga::mangatag;
    use JSON;
    use LWP::Simple;
    use Data::Dumper;
    use MyManga::mangacover;

  use MooseX::App::Command; # important
  extends qw(MyManga); # purely optional, only if you want to use global options from base class
  

  parameter 'filename' => (
      is            => 'rw',
      isa           => 'Str',
      documentation => q[ file name like: Kagami no Kuni no Harisugawa Vol.03.mobi],
  ); # Option
  
  
  command_short_description q[ Lookup Manga Mobi files & set meta-data ];

  command_long_description q[ Try to Lookup Manga Title and add cover & more infos  ];

  sub run {
      my ($self,@arr) = @_;
      my $manga = $self->{filename} or die("error!");
      my $uid = "";
      my $mangacover = MyManga::mangacover->new();
      
      if (-d $manga) {
        opendir(DIR, "$manga") or die "Could not open $manga\n";
        my $last = "";
        while ( my $filename = readdir(DIR)) {
            next if (!($filename=~/\.mobi/));
            start("$manga/$filename");
            $last = $filename;
        }
        closedir(DIR);
        searchPrint($last);
        return 1;
      }
      die("file not found!\t$manga\n") if !(-f $manga);

      searchPrint($manga);
#      my $title = cleanTitle($1) if $manga =~ /([^\/]+)\.mobi/;
#            chomp($title);      $title =~ s/^ //;      $title =~ s/ $//;
#      print "[X] MangaTag: $title\t$manga\n";
#            $mangacover->searchManga($title);
#      $uid = $mangacover->getUid;
#      die("[ERROR] Manga not found in MangaDB\n") if !($uid);
#            $mangacover->setCoverFromFile($uid,$manga);
#	      my $id = $mangacover->getMangaInfo;
#             $mangacover->printInfo($id);            
      
     # print "$title\t".parseBook($title)."\n";
        
}

sub searchPrint{
    my ($file) = @_;
    my $title = cleanTitle($1) if $file =~ /([^\/]+)\.mobi/;
            chomp($title);      $title =~ s/^ //;      $title =~ s/ $//;
      print "[X] MangaTag: $title\n";
      
       my $mangacover = MyManga::mangacover->new();
            $mangacover->searchManga($title);
        my $uid = $mangacover->getUid;
        die("[ERROR] Manga not found in MangaDB\n") if !($uid);
              $mangacover->setCoverFromFile($uid,$title);	
        my $id = $mangacover->getMangaInfo;
             $mangacover->printInfo($id);                
}


sub start {
    my ($manga) = @_;
      die("file not found!\t$manga\n") if !(-f $manga);
      my $title = cleanTitle($1) if $manga =~ /([^\/]+)\.mobi/;
            chomp($title);      $title =~ s/^ //;      $title =~ s/ $//;
      print "[X] MangaTag: $title\t$manga\n";
      my $bla = MyManga::mangacover->new();
            $bla->searchManga($title);
      my $uid = $bla->getUid;
      die("[ERROR] Manga not found in MangaDB\n") if !($uid);
            $bla->setCoverFromFile($uid,$manga);
    return $uid;
}

  sub parseBook {
      my $name = $_[0];
      
      #print "$1\n" if ($uri->as_string() =~ /Bd[\.]?(\d+)/i);
      return "v$1" if ($name =~ /[VBandol\. ]{0,4}(\d+)/);

    return -1;
  }
  
  sub cleanTitle {
      my $name = $_[0];
      #print "$1\n" if ($uri->as_string() =~ /Bd[\.]?(\d+)/i);
        $name =~ s/([VBandol\. ]{0,4}\d+)$//;
    return $name;
  }  

  #  sub do_some { print "Hello World @_\n" }

1;