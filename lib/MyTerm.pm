#!/usr/bin/perl

    package MyTerm;

     use Inline C => Config =>
                ENABLE => AUTOWRAP =>
                LIBS => "-lreadline -lncurses -lterminfo -ltermcap  ";
     use Inline C => q{ char * readline(char *); };


1;





# patchPid(2736);