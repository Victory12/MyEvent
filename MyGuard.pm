package MyGuard;
use strict;
use warnings;
use DDP;
use Exporter;
*import = \&Exporter::import;
our @EXPORT_OK = qw/guard DESTROY cancel/;
our %EXPORT_TAGS = (
    func  => [ qw/guard/ ],
    const => [ qw//  ],
);
our @EXPORT = qw//;
sub DESTROY {
    my $self = shift;
    $self->[0]->() if $self->[0];
}
sub cancel {
    $_[0][0] = undef;
}
sub guard(&) {
    my $cb = shift;
    my $self = bless [$cb], 'MyGuard';
}
1;