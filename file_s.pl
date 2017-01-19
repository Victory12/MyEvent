#!/usr/bin/perl -w
use strict;
use warnings;
use 5.010;
use Time::HiRes qw(time);
use MyEvent ;
use IO::Socket::INET;
use DDP;


my $sock = IO::Socket::INET->new(PeerAddr => 'mail.ru:80') or die;
binmode($sock); 

my $w = syswrite($sock, "GET / HTTP/1.1\nHost:mail.ru\n\n");
warn "written_first: $w";

my $read;
my $writ;
$read = MyEvent::io $sock, "r", sub {
	my $rd = sysread($sock, my $buf, 20);
	warn "read: $rd";
	
};
$writ = MyEvent::io $sock, "w", sub { 
	my $wr = syswrite($sock, "GET / HTTP/1.1\nHost:mail.ru\n\n");
	warn "written: $wr"; 
	undef $writ;      
};
my $time1; $time1 = MyEvent::timer 20, 0, sub {
    say "Fired after 1s";
};
my $p; $p = MyEvent::timer 10, 5, sub {
    state $counter = 0;
    if (++$counter > 2){
		 undef $p;	
	}
    say "Fired $counter time";
};

MyEvent::loop;