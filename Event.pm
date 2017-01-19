package Event;
use MyGuard;
use DDP;
our %waiters;
use IO::Select; 

our %waiters;
my $s = IO::Select->new();
my $timeout = 0;
sub io{
	my $fh = shift;
	my $poll = shift;
	my $cb = shift;
	$s->add($fh);
    push @{ $waiters{$fh} }, $cb;
    return guard {
        cancel_action($state);
}

}

sub loop{
	for(1..5) {
		print "\nLOOOOOP\n";
    	my @ready = $s->can_read($timeout);
    	for my $fd (@ready) {
        	for my $cb ( @{ $waiters{$fd} } ) {
				$cb->(); 
			}
		}
		@ready = $s->can_write($timeout);
    	for my $fd (@ready) {
        	for my $cb ( @{ $waiters{$fd} } ) {
				$cb->(); 
			}
		} 	
	}
}
sub cancel_action {     
	my ($fd, $cb) = @_;

	my $filen = fileno($fd);
	for my $idx (0..$#{ $fds{ $filen } }) {
		my $cb1 = $fds{ $filen }[ $idx ];
		if ($cb1 == $cb) {
			warn "remove $cb: $idx";
			splice( @{ $fds{ $filen } }, $idx, 1 );
			#p @{ $fds{ $filen }};
			if (@{ $fds{ $filen } } == 0) {
				delete $fds{ $filen };
			}
		}
	}
	vec( $in, fileno($fd), 1 ) = 0;
}
sub cancel_timer {
	my $dl = shift;
	my $interval = shift;
	print "END OF TIMER\n";
	@deadlines = grep { $_->[0] !=  $dl->[0] } @deadlines;	
}
1;
sub one_events {
	my $now = time;
	my @exec;
	if ( @deadlines and defined $deadlines[0][0][0]){
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
	my $timeout = $deadlines[0][0][0] - $now if $#deadlines != -1;
	$timeout = 1 unless $#deadlines != -1;
	
	my $nfound = select(my $res = $from, undef, undef, $timeout);
	if ( $nfound > 0 ){
		for my $fno (0..length($res)*8-1) {
			if ( vec($res, $fno, 1) ) {
				@{ $fds{$fno} }[0]->();
			}
		}

	}
	$timeout = $deadlines[0][0][0] - $now if  $#deadlines != -1;;
	#print "timeout for write $timeout\n";
	$timeout = 1 unless  $#deadlines != -1;;
	$nfound = select(undef, $res = $in, undef, $timeout);
	#print "ONFOUND $nfound on write is\n";
	if ( $nfound > 0 ){
		for my $fno (0..length($res)*8-1) {
			if ( vec($res, $fno, 1) ) {
				@{ $fds{$fno} }[1]->();
			}
		}
	}
}