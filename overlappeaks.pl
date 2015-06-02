#!/usr/bin/perl

use strict;
use warnings;

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 2) { die "Usage: overlappeaks.pl peaks positions"; }

my ($peak_fh, $position_fh) = @ARGV;

our $Sep = "\t";
open ( my $peak, "<peak_fh") || die "ERROR opening file \"$peak_fh\" for reading! $!";
my %chromosome_hash;

while ( my $line = <$peak_fh> ) {
    chomp $line;
    next if $line =~ /Chromosome/;   #Skip Header
    my ( $chromosome ) = (split( $Sep, $line ))[0]; 
    push @{$chromosome_hash{$chromosome}},$line ; # store the line(s) indexed by chromo
}
close $peak_fh;

open ( my $position, "<position_fh") || die "ERROR opening file \"$position_fh\" for reading! $!";

while ( my $line = <$position_fh> ) {
    chomp $line;
    my ( $chromosome, $position  ) = split ( $Sep, $line );
    next unless exists $chromosome_hash{$chromosome};

    foreach my $peak_line (@{$chromosome_hash{$chromosome}}) {
        my ($start,$end) = (split( $Sep, $line ))[1,2];

        if ( $position >= $start and $position <= $end) {
            print "MATCH REQUIRED-DETAILS...$line-$peak_line\n";
        }  else {
            print "NO MATCH REQUIRED-DETAILS...$line-$peak_line\n";
        }
    }
}
close $position_fh;