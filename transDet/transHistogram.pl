#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Carp;
require "common.pl";

# ASSUMPTIONS:
# - If a chromosome has at least one read in toFile, it must have at least one read in the fromFile
# - Reads are disjoint appear in increasing order in fromFile and toFile

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 3 && scalar(@ARGV) != 4) 
{ die "Usage: transHistogran.pl fromFile toFile histFile verbose"; }
# fromFile - name of the file from which the first time-step's regions are read.
# toFile   - name of the file from which the second time-step's regions are read.
# histFile - name of the file to transition histograms are written.
# verbose  - optional flag. If true, some debug output is written to standard output.

# Save the arguments into meaningfully-named variables
my ($fromFile, $toFile, $histFile, $verbose) = @ARGV;
if(not defined $verbose) { $verbose = 0; }
#if($dirtyFrac >= $cleanFrac) { die "ERROR: dirtyFrac($dirtyFrac) must be < cleanFrac($cleanFrac)!"; }

open(my $inFrom,  "<$fromFile") || die "ERROR opening file \"$fromFile\"! $!"; 
open(my $inTo,    "<$toFile")   || die "ERROR opening file \"$toFile\"! $!";
open(my $outHist, ">$histFile") || die "ERROR opening file \"$histFile\"! $!";

# Skip the header line
my $lFrom = <$inFrom>;
my $lTo = <$inTo>;

# Initialize the line number counters
my $lNumFrom = 2;
my $lNumTo = 2;

my ($toChr, $toStart, $toStop, $toState) = ("", -1, -1, -1);

my $lastChr = "";

# Maps each state to the number of times it appears in the regions of each chromosome
my %transCnt = ();   my %transCntAll = ();
# Total number of bases observed on each chromosome in the fromFile
my %numObsFrom = (); my %numObsFromAll = ();
# Total number of bases observed on each chromosome in the toFile
my %numObsTo = ();   my %numObsToAll = ();
# Total number of bases observed on each chromosome
my %numObsChr = ();  my $numObsAll = 0;
	
# Read through the from file
while(my $line = <$inFrom>) {
	my ($fromChr, $fromStart, $fromStop, $fromState, $fromLabel) = processLine($line);
	if($verbose >= 1) { print "from<$fromLabel>: $fromChr [$fromStart - $fromStop] ($fromState)\n"; }
	
	# If we've advanced to a new chromosome 
	if($lastChr ne "" && $fromChr ne $lastChr) { }
	
	# Advance to the next record in toFile that overlaps or goes past region [$fromStart - $fromStop] or advances to the next chromosome
	#readUntil($inTo, $fromChr, $fromStart, $fromStop, \$toChr, \$toStart, \$toStop, \$toState, "    ");
	while((($fromChr eq $toChr) || ($toChr eq "")) && ($toStop < $fromStart) && (my $toLine = <$inTo>))
	{ ($toChr, $toStart, $toStop, $toState) = processLine($toLine); }
	
	# While the next toFile record is on the next chromosome as the current fromFile record AND
	#       the next toFile record is overlaps the current fromFile record, 
	# keep looking for changes in their overlap region 
	
	while(($fromChr eq $toChr) && ($toStart <= $fromStop)) {
		#print "    to: $toChr [$toStart - $toStop] ($toState)\n";
		
		# Compute the overlap between regions [$fromStart - $fromStop] and [$toStart - $toStop]
		my $overlapStart = max($fromStart, $toStart);
		my $overlapStop  = min($fromStop,  $toStop);
		
		# The the two regions overlap on at least one basepair
		if($overlapStart < $overlapStop) {
			# Incorporate all the reads in the overlap region
			$transCnt{$fromChr}{$fromState}{$toState} += $overlapStop - $overlapStart;
			$numObsFrom{$fromChr}{$fromState}         += $overlapStop - $overlapStart;
			$numObsTo{$toChr}{$toState}               += $overlapStop - $overlapStart;
			$numObsChr{$fromChr}                      += $overlapStop - $overlapStart;
			
			$transCntAll{$fromState}{$toState} += $overlapStop - $overlapStart;
			$numObsFromAll{$fromState}         += $overlapStop - $overlapStart;
			$numObsToAll{$toState}             += $overlapStop - $overlapStart;
			$numObsAll                         += $overlapStop - $overlapStart;
			
			#print "    transCnt{$toState}=$transCnt{$toState}\n";
			#print "    transCnt{$fromChr}{$fromState}{$toState}=$transCnt{$fromChr}{$fromState}{$toState}, numObsFrom{$fromChr}{$fromState}=$numObsFrom{$fromChr}{$fromState}\n";
		}
				
		# Advance to the next record in toFile, if needed
		if(($toStop <= $fromStop) && (my $toLine = <$inTo>))
		{ ($toChr, $toStart, $toStop, $toState) = processLine($toLine); }
		else
		{ last; }
	}
}

# Finish processing all the regions from the last chromosome
if($lastChr ne "") { }

# Divide each count in %transCnt by the total count in numObsFrom to get the average transition probabilities
my %transProb = ();
#print "transCnt=",obj2Str(\%transCnt, "    "),"\n";
foreach my $chr (keys %transCnt) {
foreach my $fromState (keys %{$transCnt{$chr}}) {
foreach my $toState (keys %{$transCnt{$chr}{$fromState}}) {
	#print "transCnt{$chr}{$fromState}{$toState}=$transCnt{$chr}{$fromState}{$toState}, numObsFrom{$chr}{$fromState}=$numObsFrom{$chr}{$fromState}\n";
	$transProb{$chr}{$fromState}{$toState} = 
				$transCnt{$chr}{$fromState}{$toState} / 
				$numObsFrom{$chr}{$fromState};
} } }

my %transProbAll = ();
foreach my $fromState (keys %transCntAll) {
foreach my $toState (keys %{$transCntAll{$fromState}}) {
	#print "transCnt{$chr}{$fromState}{$toState}=$transCnt{$chr}{$fromState}{$toState}, numObsFrom{$chr}{$fromState}=$numObsFrom{$chr}{$fromState}\n";
	$transProbAll{$fromState}{$toState} = 
				$transCntAll{$fromState}{$toState} / 
				$numObsFromAll{$fromState};
} }


printHist(\%transProbAll, \%numObsFromAll, \%numObsToAll, $numObsAll, "    ");

foreach my $chr (keys %transProb) {
	print $outHist "$chr\n";
	
	printHist($transProb{$chr}, $numObsFrom{$chr}, $numObsTo{$chr}, $numObsChr{$chr}, "    ");
	#foreach my $fromState (sort {$a <=> $b} keys %{$transProb{$chr}}) {
	#	#print $outHist "    $fromState\n";
	#	foreach my $toState (sort {$a <=> $b} keys %{$transProb{$chr}{$fromState}}) {
	#		#print $outHist "        $toState: ",sprintf("%.2f", $transProb{$chr}{$fromState}{$toState}*100),"%\n";
	#} } 
}

close($inFrom);
close($inTo);
close($outHist);

sub processLine
{
	my ($line, $indent) = @_;
	
	chomp $line;
	my @fields = split(/\s+/, $line);
	if(scalar(@fields) < 4) { die "ERROR: wrong number of fields in line \"$line\"!"; }
	
	my ($chrom, $start, $stop, $state, $label) = @fields;
	if(not defined $label) { $label = "???"; }
	#print "    state=$state\n";
	return ($chrom, $start, $stop, $state, $label);
}



sub printHist
{
	my ($tp, $numObsFrom, $numObsTo, $numObsTotal, $indent) = @_;
	
	my %statesH = ();
	foreach my $fromState (sort {$a <=> $b} keys %$tp) {
		$statesH{$fromState} = 1;
		foreach my $toState (sort {$a <=> $b} keys %{$tp->{$fromState}}) {
			$statesH{$toState} = 1;
	} }
	my @stateL = sort {$a <=> $b} keys %statesH;
	
	print $outHist "\t",list2StrSep(\@stateL, "\t"),"\n";
	foreach my $fromState (@stateL) { 
		print $outHist "$fromState";
		foreach my $toState (@stateL) { 
			if(defined $tp->{$fromState}{$toState}) 
			{ print $outHist "\t$tp->{$fromState}{$toState}"; }
			else 
			{ print $outHist "\t"; }
		}
		print $outHist "\n";
	}
	
	print $outHist "numObsFrom\n";
	foreach my $fromState (@stateL)
	{ print $outHist "\t",(defined $numObsFrom->{$fromState}? $numObsFrom->{$fromState}/$numObsTotal: ""); }
	print $outHist "\n";
	
	
	print $outHist "numObsTo\n";
	foreach my $fromState (@stateL)
	{ print $outHist "\t",(defined $numObsTo->{$fromState}? $numObsTo->{$fromState}/$numObsTotal: ""); }
	print $outHist "\n";
}
	