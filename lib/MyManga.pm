#!/usr/bin/perl

require Exporter;
require Plugin::Tiny;
require Moose;
require Carp;
require Data::Dumper;
require File::HomeDir;
require AnyEvent::HTTPD;
require MooseX::App::Plugin::ZshCompletion;
require MooseX::App::Plugin::BashCompletion;
require MooseX::App::Plugin::Term;
require MooseX::App::Plugin::ConfigHome;



package MyManga;
    # base class of this(Arithmetic) module
    
    use MooseX::App qw(ZshCompletion BashCompletion ConfigHome Version Term);
    #
    option 'debug' => (
        is            => 'rw',
        isa           => 'Bool',
        documentation => q[set Debug mode for verbose ],
    ); # Global option

   
    has 'private' => ( 
        is              => 'rw',
    ); # not exposed
    

    
    #
    #
    #sub new()
    #{
    #        my ($class) = @_;
    #        my $self = {};
    #        
    #        $self{config} = ();
    #        
    #        print Data::Dumper::Dumper($self{config})."\n";
    #        
    #        return bless $self,$class;
    #
    #}
    #
    #sub config()
    #{
    #        #confess "usage: read->readfile(keyvalue)"    unless @_ => 2;
    #        my ($self,$key,$val) = @_;
    #        print Data::Dumper::Dumper($self{config})."\n";
    #        $self{config} = { $key => $val};
    #        print Data::Dumper::Dumper($self{config})."\n";
    #
    #        return $self;
    #
    #}
    #
    #
    #
    #sub dd(){
    #    my ($self) = @_;
    #    
    #    print Data::Dumper::Dumper($self{config})."\n";
    #
    #    my $ps  =   Plugin::Tiny->new (  prefix=>'Spammer::Plugin::' ); 
    #    
    #    for (@My::Hotpatch::EXPORT) {
    #      print "$_\n";
    #    }
    #    
    #}
    #
    #eval {
    #    use autodie qw(system);
    #    system(`backup_files`);
    #    system(`delete_files`);
    #};
    #if ($@) {
    #    warn "Error in running commands: $@\n";
    #}

1;


