#!/usr/bin/perl

use strict;
use warnings;

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 2) { die "Usage: readGeneCount.pl inFile outFile"; }

# Save the arguments into meaningfully-named variables
my ($inFile, $outFile) = @ARGV;

# Load the chromosome data
my %file = ();

open(my $inF, "<$inFile") || die "ERROR opening file \"$inFile\" for reading! $!";
# Skip the header line
<$inF>;

for(my $lnum=1; my $line=<$inF>; $lnum++) {
	chomp $line;
	my @fields = split(/\s/, $line);
	if(scalar(@fields) != 6) { die "ERROR on line $lnum of file \"$inFile\"! Expected fields (chromNum start stop ID score strand) but got ".scalar(@fields)." fields. line=\"$line\"."; }
	my ($chromNum, $start, $stop, $ID, $score, $strand) = @fields;
	push(@{$file{$chromNum}}, {start=>$start, stop=>$stop});
	#or for hash version: $genes{$chromNum}{$name} = {start=>$start, stop=>$stop};
}
close($inF);

# Save columns into a file
open(my $outF, ">$outFile") || die "ERROR opening file \"$outFile\" for writing! $!";
foreach my $chromNum (keys %file) {
	foreach my $read (@{$file{$chromNum}})
		{ print $outF "$chromNum\t$read->{start}\t$read->{stop}\n"; }
}
close($outF);