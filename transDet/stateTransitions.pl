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
if(scalar(@ARGV) != 9 && scalar(@ARGV) != 10) 
{ die "Usage: stateTransitions.pl fromFile toFile cleanTransFile noTransResistantFile noTransUnchallengedFile sourceState1,sourceState2,... destState1,destState2,... cleanThrsh noTransTrsh verbose"; }
# fromFile                - name of the file from which the first time-step's regions are read
# toFile                  - name of the file from which the second time-step's regions are read
# cleanTransFile          - name of the file to which regions that cleanly transition are written
# noTransResistantFile    - name of the file to which unchanding regions that are change-resistant are written
# noTransUnchallengedFile - name of the file to which unchanding regions that are change-unchallenged are written
# sourceState1,sourceState2,... - comma-separated list of first time-step states that the analysis focuses on
# destState1,destState2,...     - comma-separated list of second time-step states that the analysis focuses on
# cleanThrsh  - minimal fraction of bases in a region that must transition from a source state to a destination state 
#               before the region is considered a clean transition
# noTransTrsh - if a smaller fraction of bases in a region transition than this threshold, it is considered a non-transitioning region
# verbose - optional flag. If true, some debug output is written to standard output and if labels are associated with regions
#           in fromFile, they are written to the records in the output files

# Save the arguments into meaningfully-named variables
my ($fromFile, $toFile, $cleanTransFile, $noTransResistantFile, $noTransUnchallengedFile, $sourceStateStr, $destStateStr, $cleanTransThrsh, $noTransTrsh, $verbose) = @ARGV;
if(not defined $verbose) { $verbose = 0; }
# Get the lists of source and destination states, from the comma separated argument strings
my @sourceStates = split(/,/, $sourceStateStr);
my @destStates   = split(/,/, $destStateStr);
#if($dirtyFrac >= $cleanFrac) { die "ERROR: dirtyFrac($dirtyFrac) must be < cleanFrac($cleanFrac)!"; }

open(my $inFrom, "<$fromFile")                          || die "ERROR opening file \"$fromFile\"! $!"; 
open(my $inTo, "<$toFile")                              || die "ERROR opening file \"$toFile\"! $!";
open(my $outClean, ">$cleanTransFile")                  || die "ERROR opening file \"$cleanTransFile\"! $!";
open(my $outNoTransResist, ">$noTransResistantFile")    || die "ERROR opening file \"$noTransResistantFile\"! $!";
open(my $outNoTransUnchal, ">$noTransUnchallengedFile") || die "ERROR opening file \"$noTransUnchallengedFile\"! $!";

# Print out the header of the transitions files
print $outClean         "chrom\tstart\tstop\tdiff\n";
print $outNoTransResist "chrom\tstart\tstop\tdiff\n";
print $outNoTransUnchal "chrom\tstart\tstop\tdiff\n";

# Skip the header line
my $lFrom = <$inFrom>;
my $lTo = <$inTo>;

# Initialize the line number counters
my $lNumFrom = 2;
my $lNumTo = 2;

my ($toChr, $toStart, $toStop, $toState) = ("", -1, -1, -1);

# To make it possible to make decisions for a region based on its successors we record them in this list. 
my @recentRegions = ();
my $regHistSize = 1;

my $lastChr = "";

# Read through the from file
while(my $line = <$inFrom>) {
	my ($fromChr, $fromStart, $fromStop, $fromState, $fromLabel) = processLine($line);
	if($verbose >= 1) { print "from<$fromLabel>: $fromChr [$fromStart - $fromStop] ($fromState)\n"; }
	
	# If we've advanced to a new chromosome finish processing all the regions from the prior chromosome
	if($lastChr ne "" && $fromChr ne $lastChr) { processRemainingRegions(); }
	
	# Maps each state to the number of times it appears in the regions of toFile that overlap [$fromStart - $fromStop] 
	my %toStateCnt = ();
	# Total number of basepairs observed in the toFile in region [$fromStart - $fromStop]
	my $numToObs = 0;
	
	# Advance to the next record in toFile that overlaps or goes past region [$fromStart - $fromStop] or advances to the next chromosome
	#readUntil($inTo, $fromChr, $fromStart, $fromStop, \$toChr, \$toStart, \$toStop, \$toState, "    ");
	while((($fromChr eq $toChr) || ($toChr eq "")) && ($toStop < $fromStart) && (my $toLine = <$inTo>))
	{ ($toChr, $toStart, $toStop, $toState) = processLine($toLine); }
	
	# While the next toFile record is on the next chromosome as the current fromFile record AND
	#       the next toFile record is overlaps the current fromFile record, 
	# keep looking for changes in their overlap region 
	my $firstToForFromRegion = 1; # True for the first toRegion that is encountered for the current from region
	# Store whether the starting and stopping bases of the current from region represent a transition or not
	my ($startTrans, $stopTrans);
	
	while(($fromChr eq $toChr) && ($toStart <= $fromStop)) {
		#print "    to: $toChr [$toStart - $toStop] ($toState)\n";
		
		# Compute the overlap between regions [$fromStart - $fromStop] and [$toStart - $toStop]
		my $overlapStart = max($fromStart, $toStart);
		my $overlapStop  = min($fromStop,  $toStop);
		
		# The the two regions overlap on at least one basepair
		if($overlapStart <= $overlapStop) {
			# Incorporate all the reads in the overlap region
			$toStateCnt{$toState} += $overlapStop - $overlapStart;
			$numToObs += $overlapStop - $overlapStart;
			#print "    toStateCnt{$toState}=$toStateCnt{$toState}\n";
			
			# If this is the first to region and it is not empty
			if($firstToForFromRegion && ($overlapStop - $overlapStart)) {
				$startTrans = isInterestingTrans_ToStateNearDestState($fromState, $toState, \@sourceStates, \@destStates, "    "); 
				# The next to region is definitely not the first
				$firstToForFromRegion = 0;
			}
			
			# If the current to region is not empty
			if($overlapStop - $overlapStart)
			{ $stopTrans = isInterestingTrans_ToStateNearDestState($fromState, $toState, \@sourceStates, \@destStates, "    "); }

		}
				
		# Advance to the next record in toFile, if needed
		if(($toStop <= $fromStop) && (my $toLine = <$inTo>))
		{ ($toChr, $toStart, $toStop, $toState) = processLine($toLine); }
		else
		{ last; }
	}
	
	#print "    toStateCnt=",obj2Str(\%toStateCnt, "    "),"\n";
	
	# Analyze how much the current fromFile region has changed
	
	# If there was no overlap, issue a warning and skip out
	if($numToObs==0) { print "WARNING: fromFile region $fromChr : [$fromStart - $fromStop] (state=$fromState) did not overlap with any regions in the toFile!"; next; }
	
	# The fraction of times each state has appeared in the regions of toFile that overlap the current fromFile record
	my %toStateFrac = ();
	foreach my $state (keys %toStateCnt)
	{ $toStateFrac{$state} = $toStateCnt{$state} / $numToObs; }
	
	#print "    toStateFrac=",obj2Str(\%toStateFrac, "    "),"\n";
	
	# --- Compute the fraction of bases where no transition occurs
	# Consider the basepairs for which there is no state transition separately
	my $noTransFrac = 0;
	if(defined $toStateFrac{$fromState}) { $noTransFrac = $toStateFrac{$fromState}; }
	#my %toStateTransFrac = %toStateFrac; # Copy of toStateFrac without the source state
	#delete $toStateTransFrac{$destState};
	
	# --- Compute The fraction of bases in this region where we transitioned from $sourceState to $destState
	# States in %toStatTransFrac sorted in decreasing order according to their fraction
	#my @sortStates = sort {$toStateTransFrac{$b} <=> $toStateTransFrac{$a}} keys %toStateTransFrac;
	#print "sortStates=",obj2Str(\@sortStates, "    "),"\n";
	my $transFrac = 0;
	foreach my $state (@destStates) { 
		if(defined $toStateFrac{$state})
		{ $transFrac += $toStateFrac{$state}; }
	}
	
	# --- Compute The fraction of bases where we transition from $fromState to any other state.
	#     (Used for regions where the state != sourceState.)
	#my $anyTransFrac = 0; 
	#foreach my $state (keys %toStateFrac) {
	#	if($state != $fromState)
	#	{ $anyTransFrac += $toStateFrac{$state}; }
	#}
		
	addRegion($fromChr, $fromStart, $fromStop, $fromState, $fromLabel, $noTransFrac, $transFrac, $startTrans, $stopTrans, "    ");
	
	#print "    recentRegions=",obj2Str(\@recentRegions, "            "),"\n";
}

# Finish processing all the regions from the last chromosome
if($lastChr ne "") { processRemainingRegions(); }

close($inFrom);
close($inTo);
close($outClean);
close($outNoTransResist);
close($outNoTransUnchal);

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

# To make it possible to make decisions for a region based on its successors we record them in this list. 
# When a region enters we wait for $regHistSize additional regions to be included before we decide
# where it should be classified. Each region record is a hash of the form 
#    {trans=>, classFunc=>}
# When we're about to add a new region $r to @recentRegions that has size $regHistSize we look at how $r relates
# to regions in @recentRegions and set the classFunc to an appropriate function.
# We then add $r to @recentRegions and remove the oldest region $q from @recentRegions.
# Finally, we execute $q->{classFunc}, which considers the contents of @recentRegions (the regions that follow $q)
# and writes it out to the appropriate file
sub addRegion
{
	my ($chr, $start, $stop, $state, $label, $noTransFrac, $transFrac, $startTrans, $stopTrans, $indent) = @_;

	#print "${indent}addRegion($chr, $start, $stop, $state, $label, noTransFrac=$noTransFrac, transFrac=$transFrac, startTrans=$startTrans, stopTrans=$stopTrans)\n";
	my $r;
	# 3 MOTHER CATEGORIES
	# 1) yes transition from 1 to 6 (in actuality the transition should be >x% with a flexible percentage)
	if($transFrac > $cleanTransThrsh) { 
		if($verbose >= 1) { print "${indent}<$label>Clean Trans, transFrac=$transFrac > cleanTransThrsh=$cleanTransThrsh\n"; }
		$r = {startTrans=>$startTrans, stopTrans=>$stopTrans, label=>$label, 
		      classFunc=>sub { if(isInList($state, \@sourceStates)) { 
		      	print $outClean "$chr\t$start\t$stop\t$state";
		      	if($verbose >= 1) { print $outClean "\t$label"; }
		      	print $outClean "\n"; }}};
	# 2) dirty transition (y% < amount that transitions < x%)
	}
	elsif($transFrac > $noTransTrsh)
	{
		if($verbose >= 1) { print "${indent}<$label>Dirty Trans, transFrac=$transFrac, noTransFrac=$noTransFrac > noTransTrsh=$noTransTrsh\n"; }
		$r = {startTrans=>$startTrans, stopTrans=>$stopTrans, label=>$label, classFunc=>sub { } };
		# DISCART
		# # follow up A
		# # (y%<change<x%)
		# # if >z% of the region stays in original state, put in mother category 3, and
		# #    the difference between average state values > $avgStateTrsh
		# if($noTransFrac > $noTransTrsh || the difference between average state values < $avgStateTrsh)
		# #{ $r = {trans=>0, classFunc=>sub { print $outNoTrans "$chr\t$start\t$stop\t$state\n"; }}; }
		# # follow up B
		# #{ print "${indent}<$label>    No Trans\n"; $r = followupB($chr, $start, $stop, $state, $label, $anyTransFrac, $indent."    "); }
		# # otherwise, put in mother category 1
		# else
		# { print "${indent}<$label>    Actually Clean Trans ($anyTransFrac)\n"; $r = {trans=>1, label=>$label, classFunc=>sub { if($state==$sourceState) { print $outClean "$chr\t$start\t$stop\t$state\n"; }}}; }
	# 3) no transition from 1 to 6  (in actuality the transition should be <y% with a flexible percentage)
	} else {
		if($verbose >= 1) { print "${indent}<$label>No Trans, transFrac=$transFrac < noTransTrsh=$noTransTrsh\n"; }
		# follow up B
		$r = followupB($chr, $start, $stop, $state, $label, $startTrans, $stopTrans, $indent."    ");
	}
	
	#print "${indent}r=",obj2Str($r, $indent."    "),"\n";
	
	# Add the new record to @recentRegions
	push(@recentRegions, $r);
	
	# If @recentRegions is larger than the desired history length, remove the oldest record and run its classFunc to write it out appropriately
	#print "${indent}#recentRegions=",scalar(@recentRegions),"\n";
	if(scalar(@recentRegions) > $regHistSize) {
		my $oldestR = shift(@recentRegions);
		#print "${indent}oldestR=",obj2Str($oldestR, $indent."    "),"\n";
		$oldestR->{classFunc}->();
	}
}

sub processRemainingRegions
{
	while(scalar(@recentRegions)>0) {
		my $r = shift @recentRegions;
		$r->{classFunc}->();
	}
}

# are flanking regions changing?
sub followupB
{
	my ($chr, $start, $stop, $state, $label, $startTrans, $stopTrans, $indent) = @_;
	
	#print "${indent}<$label>: followupB\n";
	# Determine whether all the regions currently in @recentRegions are definitely classified as transitioning
	my $allRecentTrans = isAllRecentTrans("stopTrans", $indent."    ");
	#print "${indent}<$label>:     allRecentTrans=$allRecentTrans\n";
	
	# If all the predecessors in @recentRegions are definitely transitioning add a record where classFunc
	# will decide the transition status based on whether all of its successors are transitioning.
	if($allRecentTrans) {
		return {#trans=>($anyTransFrac > $anyTransThrsh),# && change is significant), 
		        startTrans=>$startTrans, stopTrans=>$stopTrans,
		        label=>$label,
		        classFunc=>sub {
		                      	if(isInList($state, \@sourceStates)) { 
		                         	my $allSubsequentTrans = isAllRecentTrans("startTrans", $indent."    ");
		                         	#print "${indent}<$label>:     allSubsequentTrans=$allSubsequentTrans\n";
		                         	if($allSubsequentTrans) { 
		                         		if($verbose >= 1) { print "${indent}<$label>:     Resistant\n"; }
		                         		print $outNoTransResist "$chr\t$start\t$stop\t$state";
		                         		if($verbose >= 1) { print $outNoTransResist "\t$label"; }
		                         		print $outNoTransResist "\n";
		                         	} else { 
		                         		if($verbose >= 1) { print "${indent}<$label>:     Unchallenged\n"; }
		                         		print $outNoTransUnchal "$chr\t$start\t$stop\t$state";
		                         		if($verbose >= 1) { print $outNoTransUnchal "\t$label"; }
		                         		print $outNoTransUnchal "\n";
		                         	}
		                         }
		                      }};
	} else {
		return {#trans=>($anyTransFrac > $anyTransThrsh), # && change is significant), 
		        startTrans=>$startTrans, stopTrans=>$stopTrans,
		        label=>$label,
		        classFunc=>sub { 
			     	if(isInList($state, \@sourceStates)) {
			      	if($verbose >= 1) { print "${indent}<$label>: Unchallenged\n"; }
			      	print $outNoTransUnchal "$chr\t$start\t$stop\t$state";
			      	if($verbose >= 1) { print $outNoTransUnchal "\t$label"; }
			      	print $outNoTransUnchal "\n";
		        	}
		        }};
	}
}

# Return true iff all the regions currently in @recentRegions are classified as transitioning
sub isAllRecentTrans
{
	my ($transKey, $indent) = @_;
	foreach my $r (@recentRegions) {
		#print "${indent}<$r->{label}>: $transKey=$r->{$transKey}\n";
		if(!$r->{$transKey})
		{ return 0; }
	}
	return 1;
}

# Returns true if the fromState -> toState transition is interesting
sub isInterestingTrans_anyChange
{
	my ($fromState, $toState, $sourceStates, $destStates, $indent) = @_;
	
	return $fromState != $toState;
}

# Returns true if the fromState -> toState transition is interesting
sub isInterestingTrans_ToStateNearDestState
{
	my ($fromState, $toState, $sourceStates, $destStates, $indent) = @_;
	
	foreach my $state (@$destStates) {
		if($state-1 <= $toState && $toState <= $state+1)
		{ return 1; }
	}
	return 0;
}

## Reads from $in until we observe a region that overlaps [$start - $stop] or goes past it either because
## the numeric indexes are larger or because it reaches another chromosome
## $readChr, $ReadStart, $readStop, $readState - references to the current record read from $in. Will be updated as needed
#sub readUntil
#{
#	my ($in, $chr, $start, $stop, $readChr, $readStart, $readStop, $readState, $indent) = @_;
#
#	# We try to read more from <$in> if
#	# - We're still on the same chromosome as $chr
#	# - Region [$$readStart - $$readStop] has not yet reached a point past region [$start - $stop]
#	# (Otherwise, the current region [$$readStart - $$readStop] on $$readChr is already too far along and we shouldn't push it even further)
#	print "${indent}chr=$chr, stop=$stop, readChr=$$readChr ::: ($$readStart <= $stop)=",($$readStart <= $stop),"\n";
#	if((($chr eq $$readChr) || ($$readChr eq "")) && ($$readStop < $start)) {
#		# Now we try to read all the way to the point where regions [$start - $stop] and [$$readStart - $$readStop] overlap
#		# if if they already overlap, move on to the next region in <$in> to see if it also overlaps
#		# Thus, we keep reading records from $in until 
#		# - We reach the next chromosome
#		# - Region [$$readStart - $$readStop] overlaps [$start - $stop] or is after it
#		do {
#			my $line = <$in>;
#			if($line) {
#				chomp $line;
#				($$readChr, $$readStart, $$readStop, $$readState) = split(/\s+/, $line);
#			} 
#			# If we've reached the end of the file, break out
#			else
#			{ return; }
#		# If region [$$readStart - $$readStop] hasn't yet reached the goal, keep on reading from <$in>
#		} while(($chr eq $$readChr) && ($$readStop < $start));
#	}
#}
