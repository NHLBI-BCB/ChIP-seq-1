#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Carp;

# Given DNase data with TFs, pull out bed file

# If we aren't given three command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 2) { die "Usage: DNasetoBed.pl inFile outFil"; }
# Save the arguments into meaningfully-named variables
my ($inFile, $outFile) = @ARGV;

open(my $in, "<$inFile")   || die "ERROR opening file \"$inFile\"! $!"; 
open(my $out, ">$outFile") || die "ERROR opening file \"$outFile\"! $!";

while(my $line = <$in>) {
	chomp $line; #chomp=drop the last character of the line if it is a line break
	my @fields = split(/\s+/, $line); #split by any number of white spaces
	if(scalar(@fields)!=7) { die "ERROR reading line $lNum from file \"$inFile\"!"; }
	my ($chr, $start, $stop, $TFname, $PWMscore, $dirPWMmatch, $PIQscore) = @fields;
	
	print $out "$chr\t$start\t$stop\n";
	}	
	$lNum++;
}
close($in);
close($out);
