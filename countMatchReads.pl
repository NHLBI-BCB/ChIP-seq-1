#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Carp;

require "common.pl";

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 3) { die "Usage: countMatchReadsInState.pl regionFile readsFile outFile"; }
my ($regionFile, $readsFile, $outFile) = @ARGV;

# Remove the output file to make sure that we'll overwrite it with fresh results
unlink $outFile;

open(my $regions, "<$regionFile")  || die "ERROR opening file \"$regionFile\"! $!"; 
<$regions>; # Skip the header

my %regions = ();
my $regLNum=2;
while(my $line = <$regions>) {
	chomp $line;
	
	my @data = split(/\s+/, $line);
	#if(scalar(@data)!=9) { die "ERROR in \"$regionFile\":$regLNum expected 9 fields!"; }
	my ($chr, $start, $stop) = @data;
	if($start > $stop) { ($start, $stop) = ($stop, $start); } # Ensure $start <= $stop
	
	# Add regions with a matching state to the list 
	#if($state == $tgtState)
	{ push(@{$regions{$chr}}, {start=>$start, stop=>$stop}); }
	
	$regLNum++;
}

close($regions);

#print "regions=",obj2Str(\%regions, ""),"\n";
# Count the number of reads
open(my $reads, "<$readsFile")  || die "ERROR opening file \"$readsFile\"! $!"; 
<$reads>; # Skip the header
my $numReads=0;
while(<$reads>) { $numReads++; }
close($reads);

# Print the header of the output file
open(my $out, ">$outFile")  || die "ERROR opening file \"$outFile\" for writing! $!"; 
print $out "Chr\tIndex\tCount\tRegionID\n";
close($out);

open($reads, "<$readsFile")  || die "ERROR opening file \"$readsFile\"! $!"; 
#<$reads>; # Skip the header

my $readsLNum=1;
my $curChr = "";
my $curRegID; # The current index into @{$regions{$curChr}}
while(my $line = <$reads>) {
	chomp $line;
	
	my @data = split(/\s+/, $line);
	if(scalar(@data)!=6) { die "ERROR in \"$readsFile\":$readsLNum expected 6 fields!"; }
	my ($readChr, $readStart, $readStop) = @data;
	if($readStart > $readStop) { ($readStart, $readStop) = ($readStop, $readStart); } # Ensure $readStart <= $readStop
	
	# If we've reached a new chromosome, reset the state
	if($curChr ne $readChr) {
		print "New Chromosome $readChr\n";
		# If we've just finished reading a chromosome, output its counts and erase this chromosome's state to save memory
		outputCounts($curChr, "    ");
		delete $regions{$curChr};

		$curRegID = 0;
		$curChr = $readChr;
		if(not defined $regions{$readChr})
		{ $regions{$readChr} = []; }
		#print "readChr=$readChr\n";
	}
	
	# Skip over any regions that definitely precede this read since all subsequent reads will follow this one
	while($curRegID < scalar(@{$regions{$readChr}}) &&
	      $regions{$readChr}->[$curRegID]->{stop} < $readStart)
	{ $curRegID++; }
	
	#if($readChr eq "chr1") { 
	#	print "[$readStart - $readStop], regions{$readChr}->[$curRegID]=",obj2Str($regions{$readChr}->[$curRegID], "    "),"\n";
	#	print "regions{chr1}=",obj2Str($regions{"chr1"}, ""),"\n";
	#}
	
	# Iterate over all the regions that this read overlaps without incrementing $curRegID since 
	# subsequent reads may overlap the same regions and we don't want to pass over them before we got
	# a chance to match these subsequent reads to them.
	my $overRegionID = $curRegID;
	#print "[$readStart - $readStop]\n";
	while($overRegionID < scalar(@{$regions{$readChr}})) {
		# Set the current region (used as just a shorthand so that we don't keep repeating the long array access string)
		my $curRegion = $regions{$readChr}->[$overRegionID];
		#print "    curRegion=",obj2Str($curRegion, "    "),": overRegionID=$overRegionID\n";
		# If this region overlaps the read
		if(overlaps($curRegion->{start}, $curRegion->{stop}, $readStart, $readStop)) {
			#print "    read [$readStart, $readStop] overlaps region [$curRegion->{start}, $curRegion->{stop}]\n";
			# Increment the counter on every index within the overlap between the current region and the current read
			iterOnOverlap($curRegion->{start}, $curRegion->{stop}, $readStart, $readStop, 
			              sub { my ($i, $indent) = @_;
			              	#print "        $i\n";
			              	$curRegion->{counts}->[$i-$curRegion->{start}]++;
			              }, "    ");
		}
		
		# If the next region will not overlap this read, quit out
		#print "$overRegionID+1 == ",scalar(@{$regions{$readChr}})," || $regions{$readChr}->[$overRegionID+1]->{start} > $readStop\n";
		if($overRegionID+1 == scalar(@{$regions{$readChr}}) ||
		   $regions{$readChr}->[$overRegionID+1]->{start} > $readStop) { last; }
		
		# If the next region may overlap this read, advance to it
		$overRegionID++;
	}
	
	$readsLNum++;
}
close($reads);

# Output counts for the final chromosome
if($curChr ne "")
{ outputCounts($curChr, "    "); }

# The total number of reads encountered in the reads file
#my $numReads = $readsLNum-2;

#print "regions=",obj2Str(\%regions, ""),"\n";

sub outputCounts
{
	my ($curChr, $indent) = @_;

	# Print out the counts for all the regions
	open(my $out, ">>$outFile")  || die "ERROR opening file \"$outFile\" for writing! $!"; 
	#print $out "Chr\tIndex\tCount\tRegionID\n";
	#foreach my $chr (keys %regions) { 
		my $regionID=0;
		foreach my $curRegion (@{$regions{$curChr}}) {
			if(defined $curRegion->{counts}) {
				#print "regionID=$regionID\n";
				#open(my $rout, ">$outFile.regionID_$regionID")  || die "ERROR opening file \"$outFile.regionID_$regionID\" for writing! $!"; 
				#print $rout "Chr\tIndex\tCount\n";
			
				#print "curRegion->{counts}=",obj2Str($curRegion->{counts}, "    "),"\n";
				#print "curRegion=",obj2Str($curRegion, "    "),"\n";
				for(my $idx=0; $idx<scalar(@{$curRegion->{counts}}); $idx++) {
					if(defined $curRegion->{counts}->[$idx]) { 
						print $out "$curChr\t",($idx + $curRegion->{start}),"\t",($curRegion->{counts}->[$idx]/$numReads*1000000),"\t$regionID\n";
						#print $rout "$curChr\t",($idx + $curRegion->{start}),"\t",($curRegion->{counts}->[$idx]/$numReads*1000000),"\n";
					}
					#{ print "$curChr\t",($idx + $curRegion->{start}),"\t",($curRegion->{counts}->[$idx]/$numReads*1000000),"\n"; }
				}
				
				#close($rout);
			
				#$ENV{DATA_PATH}="$outFile.regionID_$regionID"; 
				#system "/cygdrive/C/Program\\ Files/R/R-2.15.2/bin/x64/Rcmd.exe BATCH vizCountsOneRegion.R";
			}
			$regionID++;
		}
	#}
	close($out);
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
