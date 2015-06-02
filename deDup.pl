#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Carp;

# Given an input file in format "$chrom $start $stop *" with a no header, where the reads are in lexicographic order 
# of <$start, $stop> within each chromosome and chromosomes are not interleaved.
# Outputs a file where duplicate reads are removed

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 2) { die "Usage: deDupReads.pl inFile outFile"; }
# Save the arguments into meaningfully-named variables
my ($inFile, $outFile) = @ARGV;

open(my $in, "<$inFile")   || die "ERROR opening file \"$inFile\"! $!"; 
open(my $out, ">$outFile") || die "ERROR opening file \"$outFile\"! $!";
my $lNum=1;
my ($lastChr, $lastStart, $lastStop) = ("", 0, 0);
while(my $line = <$in>) {
	chomp $line;
	my @fields = split(/\s+/, $line);
	if(scalar(@fields<3)) { die "ERROR reading line $lNum from file \"$inFile\"!"; }
	my ($chr, $start, $stop) = @fields;
	
	#print "($chr, $start, $stop) - ($lastChr, $lastStart, $lastStop)\n";
	# If this is a fresh read, print it out and store it
	if($chr ne $lastChr || $start != $lastStart || $stop != $lastStop) { 
		print $out "$chr\t$start\t$stop\n";
		($lastChr, $lastStart, $lastStop) = ($chr, $start, $stop);
	}
	
	$lNum++;
}
close($in);
close($out);
