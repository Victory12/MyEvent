#!/usr/bin/perl -w
use strict;
use warnings;
use Event;
use DDP;
open (my $fh1, "<", "file1.txt");
open (my $fh4, "<", "file4.txt");
p $fh1;

my $re;
$re = Event::io $fh1, "r", sub {
    my $line = <$fh1>;
    chomp($line); 
    print  $line."--with was read\n";
    undef $re;
};
my $wr;
$wr = Event::io $fh4, "r", sub {     
        my $line2 = <$fh4>;
        chomp($line2);
    	print  $line2."--with was read2\n";
    };
Event::loop;
