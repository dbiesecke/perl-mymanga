#!/usr/bin/perl 
require Plugin::Tiny;
require Carp;
require Exporter;
require Moose;
require URI;


package MyManga::mangacover;
    use JSON;
    use LWP::Simple;
    use Data::Dumper;
    use File::Temp qw/ tempfile tempdir /;
    use JSON;
    
  use MooseX::App::Command; # important
  extends qw(MyManga); # purely optional, only if you want to use global options from base class
  

  parameter 'manga_short_name' => (
      is            => 'rw',
      isa           => 'Str',
      documentation => q[Manga short name like 100_sind_zu_wenig],
  ); # Option
  
  
  command_short_description q[ example];

  command_long_description q[ example desc  ];

  sub run {
      my ($self,@arr) = @_;
      my $manga = $self->{manga_short_name} or die("error!");
        $self->searchManga($manga);
         print "[X] $manga not found in MangaDB\n" if !($self->getUid);

	      my $id = $self->getMangaInfo;
	
        $self->printInfo($id);
        &downloadCover($id);
      
  }

  sub setCoverFromFile(){
    my ($self,$uid,$file) = @_;
    my $success = 0;
	my ($dir, $fh, $filename, $line);
	   $dir = tempdir( CLEANUP =>  0 );
	  ($fh, $filename) = tempfile( DIR => $dir );
	  
	my $vol = parseVolume($file);
	my $front  = $self->getCover($uid,$vol,"front");
	( (print "ERROR - $uid $file\n") && (return) ) if !($front);
	
          my $cmd =  "mobi2mobi --author \"".$self->getAuthor()."\" --coverimage $front --outfile \"$file.new\" \"$file\" >/dev/null 2>/dev/null";
	  system($cmd);
	  my $filesize = (stat("$file.new"))[7] if ( -f "$file.new");
	  system("cp \"$file.new\" '".$file."' && rm \"$file.new\"") if ( ( -f "$file.new") && ($filesize > 1));
	 # print "\t$cmd\t$&\n";
	  print "[X] Set Cover and Author to $file SUCCESS\n";

    return $self;
  }


sub loadUp(){
    my $mudb;
    my $home = "$ENV{'HOME'}";
    my $mudbfile = $home."/.mudb.json";
    if (-f $mudbfile) {
	    open(FILE,'<',$mudbfile);
		  while (<FILE>) {
		    $mudb .= $_;
		  }
	    close(FILE);
    }else {
	    print "[X] mudb.json not found, downloading it...\n";
	    $mudb = get('http://mcd.iosphe.re/api/v1/database/');
	    open(my $fh,'>',$mudbfile);
		    print $fh $mudb;
	    close($fh);	
    }
    return decode_json($mudb);
}




sub searchManga(){
  my $self = shift;
  $self->{ref} = {};
	my $search = $_[0];
	my $db = loadUp();
# 	print "[Search] $search\n";
	foreach my $id (keys %{ $db } ){
		foreach my $title (@{ $db->{$id} }) {
			#print $title."\n" if ( $title=~ /$search/ );
			next if not ($title =~/^$search$/i);
			$self->{ref} = decode_json(get('http://mcd.iosphe.re/api/v1/series/'.$id.'/'));
		 	return $self;
		}
	}

}

sub getCover(){
	  my $self = shift;
    	my ($uid,$chapter,$type) = @_;
	

	my ($dir, $fh, $filename, $line);
	
	$dir = tempdir( CLEANUP =>  0 );
	
	($fh, $filename) = tempfile( DIR => $dir );
	my $url = 'http://mcd.iosphe.re/n/'.$uid.'/'.$chapter.'/'.$type.'/a';
	getstore($url,$filename);
	my $filesize = (stat($filename))[7];
	return if $filesize <= 1;
	
	print "[X] Cover Found\t$filename\t$url\n";
	return $filename;
	
	
	
}

sub getMangaInfo(){
  my $self = shift;
  return $self->{ref};
}

sub getUid(){
  my $self = shift;
  return $self->{ref}->{MUid} if ($self->{ref}->{MUid});
}
sub getTitel(){
  my $self = shift;
  return $self->{ref}->{Title} if ($self->{ref}->{Title});
}
sub getAuthor(){
  my $self = shift;
  return $self->{ref}->{Authors}[0] if ($self->{ref}->{Authors}[0]);
}
sub getReleaseYear(){
  my $self = shift;
  return $self->{ref}->{ReleaseYear} if ($self->{ref}->{ReleaseYear});
}
sub getVolumes(){
  my $self = shift;
  return $self->{ref}->{VolumesAvailable} if ($self->{ref}->{VolumesAvailable});
}
sub downloadCover(){
    my $manga = $_[0];
    my $int = 0;
    $int = $_[1] if ( ($_[1]) && ($_[1] > 1));
    die("no cover in hash -> downloadCover\n") if !($manga->{Covers}->{a});
    
    

    foreach my $cover (@{ $manga->{Covers}->{a} } ){
	  next if !($cover->{Side} eq 'front');
	  getstore($cover->{Normal}, $manga->{Title}.".v".$cover->{Volume}.".jpg");

# 	   print Dumper($cover)."\n";
    }
    
}

sub printInfo(){
    my $self = shift;
  
    my $manga = $_[0];
    die("no MUid hash where given -> printInfo\n") if !($manga->{MUid});
      print "".$manga->{Title}."(".$manga->{ReleaseYear}.")\tAuthor:".$manga->{Authors}[0]."";
      print "\nStatus:\t";  
      print "\tCOMPLETE" if ( $manga->{StatusTags}->{Completed} );
      print "\t [".$manga->{VolumesAvailable}."/".$manga->{Volumes}."] (UID:".$manga->{MUid}.")\n";
      print "Tags\t\t".join(",",@{ $manga->{Tags} })."\n";
    return $self;
}

  sub parseVolume {
    #my $self = shift;
      my $name = $_[0] or return;
      return "$1" if ($name =~ /[VBandol\. ]{0,4}(\d+)/);
  }
  
  sub cleanTitle {
      my $self = shift;
      my $name = $_[0];
         $name =~ s/([VBandol\. ]{0,4}\d+)$//;
      chomp($name);
      $name =~ s/^ //;      $name =~ s/ $//;	 
    return $name;
  }  

  #  sub do_some { print "Hello World @_\n" }

1;