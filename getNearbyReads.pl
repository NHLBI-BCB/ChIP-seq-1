#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Carp;

require "common.pl";

# Input: reads file with format "Chr Start Stop Code Num -" (reads within a chromosome must be in increasing order of starts)
# Input: location file with format "Chr Loc" (locations within a chromosome are must be in increasing order)
# Output: 
#    Identifies the reads that are within the region [loc-$neighborhoodSize, loc+$neighborhoodSize] of any location in $locationFile
#    Groups the reads in the region into windows of size $windowSize, and outputs with one row for each location in the following format:
#    "Chr locCenter locStart locEnd winCount_0 winCount_1 ... winCount_n"
#    where winCount = number of reads in the window / $windowSize, one for each window in the region of size $neighborhoodSize*2 around each location.

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 5) { die "Usage: getNearbyReads.pl readsFile locationFile outFile neighborhoodSize windowSize"; }
my ($readsFile, $locationFile, $outFile, $neighborhoodSize, $windowSize) = @ARGV;

# Read the regions file into the regions hash, which maps each chromosome to a list of hashes, each of the form:
# {loc=>, start=>start of region around loc, stop=>end of region around loc}
my $regions = readRegions($locationFile, $neighborhoodSize);

#print "regions=",obj2Str($regions, ""),"\n";

# Load the reads file, align the reads to the regions, updating the %$regions hash with the counts of reads within each region
my $numReads = loadReadsAndAlignToRegions($readsFile, $regions);

#print "numReads=$numReads, regions=",obj2Str($regions, ""),"\n";

# Normalize the read counts by millions of reads
scaleCounts($regions, 1 / ($numReads / 1000000));

#print "regions=",obj2Str($regions, ""),"\n";

open(my $out, ">$outFile")  || die "ERROR opening file \"$outFile\" for writing! $!"; 
# Print the header that doesn't deal with windows
print $out "Chr\tLoc\tLocRegStart\tLocRegEnd";

# Print out the counts for all the regions
my $headerPrinted=0;
foreach my $chr (keys %$regions) {
	# For debugging: Print out a table of un-windowed read counts, with one column per region
	#for(my $idx=0; $idx<($neighborhoodSize*2); $idx++) {
	#	print "$chr\t$idx";
	#	foreach my $curRegion (@{$regions->{$chr}}) {	
	#		if(defined $curRegion->{counts}->[$idx])
	#		{ print "\t$curRegion->{counts}->[$idx]"; }
	#		else
	#		{ print "\t0"; }
	#	}
	#	print "\n";
	#}
	
	my $regionID=0;
	foreach my $curRegion (@{$regions->{$chr}}) {
		if(defined $curRegion->{counts}) {
			my $winCounts = windowReadCounts($outFile, $regions, $chr, $regionID, $neighborhoodSize, $windowSize);
			
			# If this is the first window of the first chromosome, print out the header that identifies the range of each window
			if(!$headerPrinted) {
				for(my $i=0; $i<scalar(@$winCounts); $i++)
				{ print $out "\twin[",($windowSize*$i),"-",($windowSize*($i+1)),"]"; }
				print $out "\n";
				$headerPrinted=1;
			}
			print $out "$chr\t$curRegion->{loc}\t$curRegion->{start}\t$curRegion->{stop}";
			foreach my $c (@$winCounts)
			{ print $out "\t$c->{cnt}"; }
			print $out "\n";
		}
		$regionID++;
	}
}
close($out);

# Read from the given file of genome locations all the target regions that are +/- $neighborhoodSize away from each location.
# Returns the resulting hash of regions, which maps each chromosome to a list of hashes, each of the form:
# {loc=>, start=>start of region around loc, stop=>end of region around loc
sub readRegions
{
	my ($locationFile, $neighborhoodSize) = @_;

	open(my $locs, "<$locationFile")  || die "ERROR opening file \"$locationFile\"! $!"; 
	#<$locs>; # Skip the header
	
	my %regions = ();
	my $locLNum=2;
	while(my $line = <$locs>) {
		chomp $line;
		my @data = split(/\s+/, $line);
		if(scalar(@data)!=2) { die "ERROR in \"$locationFile\":$locLNum expected 2 fields!"; }
		my ($chr, $loc) = @data;
		push(@{$regions{$chr}}, {loc=>$loc, start=>($loc-$neighborhoodSize), stop=>($loc+$neighborhoodSize)});
		
		$locLNum++;
	}

	close($locs);
	
	return \%regions;
}

# Loads the reads contained in $readsFile and aligns them to the regions in the regions file, which are loaded by function
# readRegions(). Adds to the hash of each region the field counts, which is a list with one element for each genome location
# between region->{start} and region->{stop} (inclusive) that records the number of reads that overlap this location.
# Returns the total number of reads.
sub loadReadsAndAlignToRegions
{
	my ($readsFile, $regions) = @_;
	
	open(my $reads, "<$readsFile")  || die "ERROR opening file \"$readsFile\"! $!"; 
	#<$reads>; # Skip the header
	
	my $readsLNum=1;
	my $numReads=0;
	my $curChr = "";
	my $curRegID; # The current index into @{$regions->{$curChr}}
	while(my $line = <$reads>) {
		chomp $line;
		
		my @data = split(/\s+/, $line);
		if(scalar(@data)<3) { die "ERROR in \"$readsFile\":$readsLNum expected >=3 fields!"; }
		my ($readChr, $readStart, $readStop) = @data;
		if($readStart > $readStop) { ($readStart, $readStop) = ($readStop, $readStart); } # Ensure $readStart <= $readStop
		
		# If we've reached a new chromosome, reset the state
		if($curChr ne $readChr) {
			#print "New Chromosome $readChr\n";
			$curRegID = 0;
			$curChr = $readChr;
			if(not defined $regions->{$readChr})
			{ $regions->{$readChr} = []; }
			#print "readChr=$readChr\n";
		}
		
		# If we've not yet reached the end of this chromosome's regions, process this read
		if((defined $regions->{$curChr}) && ($curRegID < scalar(@{$regions->{$curChr}}))) {
			# Skip over any regions that definitely precede this read since all subsequent reads will follow this one
			while($curRegID < scalar(@{$regions->{$readChr}}) &&
			      $regions->{$readChr}->[$curRegID]->{stop} < $readStart)
			{ $curRegID++; }
			
			#if($readChr eq "chr1") { 
			#	print "[$readStart - $readStop], regions{$readChr}->[$curRegID]=",obj2Str($regions->{$readChr}->[$curRegID], "    "),"\n";
			#	print "regions{chr1}=",obj2Str($regions->{"chr1"}, ""),"\n";
			#}
			
			# Iterate over all the regions that this read overlaps without incrementing $curRegID since 
			# subsequent reads may overlap the same regions and we don't want to pass over them before we got
			# a chance to match these subsequent reads to them.
			my $overRegionID = $curRegID;
			#print "[$readStart - $readStop], overRegionID=$overRegionID < #regions{$readChr}=",scalar(@{$regions->{$readChr}}),"\n";
			while($overRegionID < scalar(@{$regions->{$readChr}})) {
				# Set the current region (used as just a shorthand so that we don't keep repeating the long array access string)
				my $curRegion = $regions->{$readChr}->[$overRegionID];
				#print "    curRegion=",obj2Str($curRegion, "    "),": overRegionID=$overRegionID\n";
				# If this region overlaps the read
				if(overlaps($curRegion->{start}, $curRegion->{stop}, $readStart, $readStop)) {
					#print "    read [$readStart, $readStop] overlaps region [$curRegion->{start}, $curRegion->{stop}]\n";
					# Increment the counter on every index within the overlap between the current region and the current read
					iterOnOverlap($curRegion->{start}, $curRegion->{stop}, $readStart, $readStop, 
					              sub { my ($i, $indent) = @_;
					              	#print "$overRegionID:        $i: ",($i-$curRegion->{start}),"\n";
					              	$curRegion->{counts}->[$i-$curRegion->{start}]++;
					              }, "    ");
				}
				
				# If the next region will not overlap this read, quit out
				#print "$overRegionID+1 == ",scalar(@{$regions->{$readChr}}),"\n";
				#if($overRegionID+1 != scalar(@{$regions->{$readChr}})) { print " || $regions->{$readChr}->[$overRegionID+1]->{start} > $readStop\n"; }
				
				if($overRegionID+1 == scalar(@{$regions->{$readChr}}) ||
				   $regions->{$readChr}->[$overRegionID+1]->{start} > $readStop) { last; }
				
				# If the next region may overlap this read, advance to it
				$overRegionID++;
			}
		}
		
		$readsLNum++;
		$numReads++;
	}
	close($reads);
	
	# The total number of reads encountered in the reads file
	return $numReads;
}

# Returns true of regions [$start1, $stop1] and [$start2, $stop2] overlap
sub overlaps
{
	my ($start1, $stop1, $start2, $stop2) = @_;
	        # [  1  ]       [      1        ]
	        #     [   2 ]      [   2  ]
	return ($start1<=$start2 && $start2<=$stop1) ||
	        #   [  1  ]      [  1  ]  
	        # [   2 ]     [     2     ]
	       ($start2<=$start1 && $start1<=$stop2);
}

# Apply the function iteratively on each point within the overlap of regions [$start1, $stop1] and [$start2, $stop2]
sub iterOnOverlap
{
	my ($start1, $stop1, $start2, $stop2, $mapF, $indent) = @_;
	
	my ($overStart, $overStop) = overlapRegions($start1, $stop1, $start2, $stop2, $indent."    ");
	for(my $i=$overStart; $i<=$overStop; $i++)
	{ $mapF->($i, $indent."    "); }
}

# Returns the start and stop of the overlap of the regions [$start1, $stop1] and [$start2, $stop2]
sub overlapRegions
{
	my ($start1, $stop1, $start2, $stop2, $indent) = @_;
	
	return (max($start1, $start2), min($stop1, $stop2));
}

sub scaleCounts
{
	my ($regions, $multFactor) = @_;
	
	my $firstChr=1;
	foreach my $chr (keys %$regions) {
		foreach my $curRegion (@{$regions->{$chr}}) {
			if(defined $curRegion->{counts}) {
				for(my $i=0; $i<scalar(@{$curRegion->{counts}}); $i++) {
					if(defined $curRegion->{counts}->[$i])
					{ $curRegion->{counts}->[$i] *= $multFactor; }
				}
			}
		}
	}
}

# Given a chromosome and regionID windows the read counts within this region (size $neighborhoodSize*2) into disjoint 
# windows of size $windowSize and returns the list of windowed counts, each of which is a hash of the form:
# {chr=>, loc=>, cnt=>}
sub windowReadCounts {
	my ($outFile, $regions, $chr, $regionID, $neighborhoodSize, $windowSize) = @_;

	open(my $outCnts, ">$outFile.counts.$chr.$regionID")  || die "ERROR opening file \"$outFile.counts.$chr.$regionID\" for writing! $!"; 
	print $outCnts "Chr\tIndex\tCount\tRegionID\n";
			
	#print "curRegion->{counts}=",obj2Str($curRegion->{counts}, "    "),"\n";
	#print "curRegion=",obj2Str($curRegion, "    "),"\n";
	#for(my $idx=0; $idx<scalar(@{$curRegion->{counts}}); $idx++) {
	for(my $idx=0; $idx<($neighborhoodSize*2); $idx++) {
		if(defined $regions->{$chr}->[$regionID]->{counts}->[$idx])
		{ print $outCnts "$chr\t$idx\t$regions->{$chr}->[$regionID]->{counts}->[$idx]\t0\n"; }
		else
		{ print $outCnts "$chr\t$idx\t0\t0\n"; }
	}
	
	close($outCnts);
	#print "$regionID: $outFile.counts\n";
	#print "------------------\n";
	#system "cat $outFile.counts";
	#print "\n";
	
	sys("./windowCountsDisj.pl $outFile.counts.$chr.$regionID $outFile.winCounts.$chr.$regionID $windowSize 0", 0);
	system "rm $outFile.counts.$chr.$regionID";
	
	my $winCounts = readWindowedCountsFile("$outFile.winCounts.$chr.$regionID", "    ");
	system "rm $outFile.winCounts.$chr.$regionID";
	return $winCounts;
}

# Reads the windowed counts file in format "chr loc count", with a header and return 
# a list of {chr=>, loc=>, cnt=>} hashes
sub readWindowedCountsFile
{
	my ($fName, $indent) = @_;
	
	my @ret = ();
	open(my $wins, "<$fName")  || die "ERROR opening file \"$fName\" for reading! $!"; 
	<$wins>;# Skip the header
	
	my $winLNum=1;
	while(my $lineW = <$wins>) {
		chomp $lineW;
		
		my @data = split(/\s+/, $lineW);
		if(scalar(@data)<3) { die "ERROR in \"$fName\":$winLNum expected >=3 fields!"; }
		my ($chrW, $locW, $countW) = @data;
		push(@ret, {chr=>$chrW, loc=>$locW, cnt=>$countW});
		
		$winLNum++;
	}
	close($wins);

	return \@ret;
}

sub sys
{
	my ($cmd, $verbose) = @_;
	
	if($verbose) { print "$cmd\n"; }
	system $cmd;
}