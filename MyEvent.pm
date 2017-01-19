package MyEvent;

use strict;
use warnings;
use MyGuard qw/guard DESTROY cancel/;;
use DDP;
use AnyEvent::Util qw(fh_nonblocking);
use POSIX qw(strftime);
use Time::HiRes qw(time);
my %fds;
my @deadlines;
my $in = '';
my $from = '';
my $dl;


$SIG{__WARN__} = sub {
	my $msg = shift;
	my $t = time;
	warn sprintf "%s.%03d %s", strftime("%Y-%m-%d %H:%M:%S", localtime( int($t) )), int(($t - int($t))*1000) , $msg;
};

sub io {
	my $fd = shift;
	my $poll = shift;
	my $cb = shift;
	
	fh_nonblocking($fd,1);								 #non block 
	vec( $in, fileno($fd),1 ) = 1 if $poll eq 'w';  	 #for select
	vec( $from, fileno($fd),1 ) = 1 if $poll eq 'r';     #for select
	my $nfile = fileno($fd);
	push @{ $fds{ $nfile } //= [] }, $cb; 				 #put cb in gloval struct 

	return guard {										 #delete io
        my $filen = fileno($fd);
		for my $idx (0..$#{ $fds{ $filen } }) {
			my $cb1 = $fds{ $filen }[ $idx ];
			if ($cb1 == $cb) {
				warn "remove $cb: $idx";
				splice( @{ $fds{ $filen } }, $idx, 1 );
				if (@{ $fds{ $filen } } == 0) {
					delete $fds{ $filen };
				}
			}
		}
		vec( $in, fileno($fd), 1 ) = 0;
	}
}
sub helper_timer {
	my $deadline = shift;
	my $cb = shift;
	$dl = [ $deadline, $cb ];
	if (defined $deadlines[0][0][0]){
		@deadlines = sort { $a->[0][0] <=> $b->[0][0] } @deadlines, $dl;
	}
	else{
		@deadlines = $dl;
	}
	return $dl;
}
sub timer {
	my ( $t, $interval, $cb ) = @_;
	my $another;
	my $deadline;
	my $dl;
	if ($interval) {
		$deadline = [
			time + $t, 
			$another = sub {
				my $deadline = [time + $interval, $another];
				$dl = helper_timer ($deadline, $cb);
			}
		];		
    } else {
		$deadline = [time + $t];
	}
	$dl = helper_timer ($deadline, $cb);
    return guard {
 		print "END OF TIMER\n";
		@deadlines = grep { $_->[0] !=  $dl->[0] } @deadlines;	
	}
}

sub one_event {
	my $now = time;
	my @exec;
	if ( @deadlines and defined $deadlines[0][0][0]){
		print "\nwe in timer $deadlines[0][0][0]\n";
		print "and now is $now\n";
		my $nn = time;
		print "but really is $nn\n\n";
		push @exec, shift @deadlines while (defined $deadlines[0][0][0] and $deadlines[0][0][0] <= $now );
    	for my $dle (@exec) {
        	if (defined $dle->[0]->[1]) {
        		$dle->[0]->[1]->() ;
        		print "now $now\n";
				print "deadline $deadlines[0][0][0]\n";
        	}
        	$dle->[1]->(); 
		}
	}	
	my $timeout = $#deadlines != -1 ? $deadlines[0][0][0] - $now : 1;
	my $nfound = select(my $res_from = $from, my $res_in = $in, undef, $timeout);
	print "NFOUND = $nfound with timeout = $timeout\n";
	if ( $nfound > 0 ) {
		for my $fno (0..length($res_from)*8-1) {
			if ( vec($res_from, $fno, 1) ) {
				@{ $fds{$fno} }[0]->();
			}
		}
		for my $fno (0..length($res_in)*8-1) {
			if ( vec($res_in, $fno, 1) ) {
				@{ $fds{$fno} }[1]->();
			}
		}
	}
}

sub loop {
	one_event while 1;
}

1;
