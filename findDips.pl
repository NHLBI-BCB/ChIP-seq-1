#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Carp;

require "common.pl";

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 8) { die "Usage: findDips.pl countsFile dipsFile slopeLength dipSizeThreshold dipHeighAroundCenter maxDipCenterSize maxZeroes visualize"; }
my ($countsFile, $dipsFile, $slopeLength, $dipSizeThreshold, $dipHeighAroundCenter, $maxDipCenterSize, $maxZeroes, $visualize) = @ARGV;
print "dipsFile=$dipsFile\n";
## Debug file
#open(my $debug, ">${dipsFile}.debug")  || die "ERROR opening file \"${dipsFile}.debug\" for writing! $!"; 
#print $debug "Chr\tIndex\tCount\n";

open(my $counts, "<$countsFile")  || die "ERROR opening file \"$countsFile\" for reading! $!"; 
<$counts>; # Skip the header

my $cntLNum=2;
my %allDips = ();
my $curChr = "";
my $curRegionID=-1;
my $numDipsInRegion=0;
my $rout;

# Number of windows during which consecutive drops, rises or zeroes were seen
my $droppingSlopeCnt=0;
my $risingSlopeCnt=0;
my $zeroCnt=0;
# The counts during the current dip and their associated absolute locations
my @dipCnts = ();
my @dipLocs = ();
# The absolute location of the current dip's starting point (all entries in @dipCnts are offset relative to this location)
my $dipStartLoc=0;
# The index of the current dip's bottom within @dipCnts
my $dipBottomIdx=0;
# The count and loc fields of the most recent window
my $lastWinCnt=-1;
my $lastWinLoc=-1;

# Hold the data of the last record read from the counts file
my ($chr, $loc, $cnt, $regionID);

while(my $line = <$counts>) {
	chomp $line;
	
	my @data = split(/\s+/, $line);
	if(scalar(@data)!=4) { die "ERROR in \"$countsFile\":$cntLNum expected 4 fields!"; }
	($chr, $loc, $cnt, $regionID) = @data;
	
	#if($cnt!=0) { print $debug "$chr\t$loc\t$cnt\t0\n"; }
	
	# If we've reached a new chromosome reset reading state
	if($curChr ne $chr) {
		endRegion();
		
		$curChr = $chr;
		resetDip();
		$lastWinCnt=-1;
		$lastWinLoc=-1;
	}
	
	if($regionID!=$curRegionID) {
		endRegion();
		$curRegionID=$regionID;
		startRegion();
	}
	
	if($visualize) { print $rout "$curChr\t$loc\t$cnt\tDips\t0\n"; }
	
	# If this is not the first window of this chromosome
	if($lastWinCnt>=0) {		
		# If the current read is empty or this read is preceded my multiple missing reads
		if($cnt==0 || $loc-$lastWinLoc>1) {
			# Increment the number of consecutive zeroes observed
			$zeroCnt += ($cnt==0? 1: 0) + ($loc-$lastWinLoc-1);
			#print "$loc: zeroCnt=$zeroCnt, $loc-$lastWinLoc\n";
			
			# If we've seen too many zero reads, abort the dip
			if($zeroCnt > $maxZeroes) 
			{ resetDip(); }
		} 
		
		# If the current read is non-empty (it may have been preceded by missing reads but this one isn't empty
		if($cnt>0) {
			my $slope = $cnt - $lastWinCnt;
			#if($curChr eq "chr18" && $curRegionID==159) { print "$chr, $loc=>$cnt, slope=$slope, droppingSlopeCnt=$droppingSlopeCnt, risingSlopeCnt=$risingSlopeCnt, zeroCnt=$zeroCnt\n"; }
			
			# Reset the number of zeros observes
			$zeroCnt=0;
						
			# If we're in the middle of a falling slope
			if($droppingSlopeCnt>0 && $risingSlopeCnt==0) {
				# Add the current count to the dip
				push(@dipCnts, $cnt);
				push(@dipLocs, $loc);
				
				# If we're continuing the falling slope
				if($slope<0) { $droppingSlopeCnt++; }
				
				# If we're rising, start counting the rise
				if($slope>0) {
					$risingSlopeCnt++;
					# The index of the dip's bottom is equal to the index of the last entry in current instance of @dipCnts
					$dipBottomIdx = scalar(@dipCnts)-1;
					
					#if($curChr eq "chr18" && $curRegionID==159) { print "    ---- Dip bottom ---- \n"; }
				}
				
				# If we're stable, we add the count to the dip but don't increment the dropping slope counter
			}
			
			# Otherwise, if we're in the middle of a rising slope
			elsif($risingSlopeCnt>0) {
				# If we're continuing the rising slope
				if($slope>0) { 
					$risingSlopeCnt++;
				}
				
				# If we're falling, see if we've completed a valid dip and reset the state of our measurement
				if($slope<0) {
					#if($curChr eq "chr18" && $curRegionID==159) { print "    >>>> End of Dip\n"; }
					# Evaluate the completed dip to verify that it meets out criteria and if so, record it
					endOfDip();
					
					resetDip();
				# If we're not falling
				} else {
					# Add the current count to the dip
					push(@dipCnts, $cnt); 
					push(@dipLocs, $loc);
				}
				
				# If we're stable, we add the count to the dip but we don't increment the rising slope counter
			}
			
			# If we're not in the middle of a dip, (note that this is an if, not an elsif, so we'll enter
			# this condition if we've just decided to abort a dip).
			if($droppingSlopeCnt==0) {
				# If we've just started a drop, record it
				if($slope<0) {
					#if($curChr eq "chr18" && $curRegionID==159) { print "    <<<< Start of Dip, loc=$lastWinLoc\n"; }
					$droppingSlopeCnt++;
					$dipStartLoc=$lastWinLoc;
					# Both the last count and this one are included in the dip since they 
					# both contribute to the falling slope
					push(@dipCnts, $lastWinCnt);
					push(@dipLocs, $lastWinLoc);
					push(@dipCnts, $cnt);
					push(@dipLocs, $loc);
				}
			}
		}
	}
	$lastWinCnt = $cnt;
	$lastWinLoc = $loc;
}
# Check if there was a valid dip at the end of the file and if so, record it
endOfDip();
endRegion();

close($counts);

#print "allDips=",obj2Str(\%allDips, "    "),"\n";

# Sort the dips within each chromosome and print them out
open(my $dips, ">$dipsFile")  || die "ERROR opening file \"$dipsFile\" for writing! $!"; 
print $dips "Chr\tdipStart\tdipCenter\tdipEnd\tdipSize\tdipCenterHeight\n";

foreach my $chr (keys %allDips) {
	$allDips{$chr} = [sort {$a->{dipCenterHeight} <=> $b->{dipCenterHeight}} @{$allDips{$chr}}];
	foreach my $dip (@{$allDips{$chr}}) {
		print $dips "$chr\t$dip->{dipStart}\t$dip->{dipCenter}\t$dip->{dipEnd}\t$dip->{dipSize}\t$dip->{dipCenterHeight}\n";
		#for(my $i=0; $i<scalar(@{$dip->{dipLocs}}); $i++)
		#{ print $debug "$chr\t",$dip->{dipLocs}->[$i],"\t",$dip->{dipCnts}->[$i],"\n"; }
	}
}

close($dips);
#close($debug);

sub resetDip
{
	#print "---- Resetting ----\n";
	$droppingSlopeCnt=0;
	$risingSlopeCnt=0;
	$zeroCnt=0;
	@dipCnts=();
	@dipLocs=();
	$dipStartLoc=0;
}

sub endOfDip
{
	# If the dip was sufficiently large
	if($droppingSlopeCnt >= $slopeLength && $risingSlopeCnt >= $slopeLength) {
		# If the end of the dip was a sequence of equal counts, we would have included them all in the dip 
		# since we didn't know that they'd be the dip's highest point. As such, remove them from the end of the dip.
		while(scalar(@dipCnts)>1 && $dipCnts[scalar(@dipCnts)-1]==$dipCnts[scalar(@dipCnts)-2])
		{ splice(@dipCnts, -1); splice(@dipLocs, -1); }
		
		my $curDipSize = min($dipCnts[0], $cnt) - $dipCnts[$dipBottomIdx];
		my ($dipStart, $dipEnd);
		if($curDipSize >= $dipSizeThreshold) {
			# Find the region around the dip's center that has height <= $dipHeighAroundCenter
			# First look earlier than the dip's bottom
			$dipStart = $dipBottomIdx-1;
			while($dipCnts[$dipStart] - $dipCnts[$dipBottomIdx] < $dipHeighAroundCenter && $dipStart>=0) 
			{ $dipStart--; }
			if($dipStart<0) { die "Failed to find the start of the dip's main region before we ran into the dip's real start"; }
			
			$dipEnd = $dipBottomIdx+1;
			#if($curChr eq "chr18" && $curRegionID==159) { print "#dipCnts=",scalar(@dipCnts),", dipCnts[$dipEnd]=$dipCnts[$dipEnd], dipCnts[$dipBottomIdx]=$dipCnts[$dipBottomIdx], dipHeighAroundCenter=$dipHeighAroundCenter\n"; }
			while($dipEnd<scalar(@dipCnts) && $dipCnts[$dipEnd] - $dipCnts[$dipBottomIdx] < $dipHeighAroundCenter) { $dipEnd++; }
			if($dipEnd>=scalar(@dipCnts)) { die "Failed to find the end of the dip's main region before we ran into the dip's real end"; }
			
			#if($curChr eq "chr18" && $curRegionID==159) { 
			#	print "[$dipStart - $dipEnd] (#",($dipLocs[$dipEnd]-$dipLocs[$dipStart]),"), maxDipCenterSize=$maxDipCenterSize\n";
			#	print "dipLocs=",obj2Str(\@dipLocs, "    "),"\n";
			#}
			# If the dip's main region is too large, compute the region of size $maxDipCenterSize centered at the bottom
			if($dipLocs[$dipEnd]-$dipLocs[$dipStart] > $maxDipCenterSize) {
				# Iterate $dipStart from $dipBottomIdx-1 backwards until we reach a location $maxDipCenterSize/2 away or reach the start of the dip
				$dipStart = $dipBottomIdx-1;
				#if($curChr eq "chr18" && $curRegionID==159) { print "Start: $dipLocs[$dipBottomIdx] - $dipLocs[$dipStart] ceil($maxDipCenterSize/2)=",ceil($maxDipCenterSize/2),"\n"; }
				while($dipStart>0 && ($dipLocs[$dipBottomIdx] - $dipLocs[$dipStart-1]) <= ceil($maxDipCenterSize/2)) { 
					$dipStart--;
					#if($curChr eq "chr18" && $curRegionID==159) { print "start: [$dipLocs[$dipStart] - $dipLocs[$dipBottomIdx] - $dipLocs[$dipEnd]] (#",($dipLocs[$dipEnd]-$dipLocs[$dipStart]),")\n"; }
				}
				#if($dipLocs[$dipBottomIdx] - $dipLocs[$dipStart] > ceil($maxDipCenterSize/2))
				#{ print "!!!!!! $curChr, regionID=$regionID, $dipLocs[$dipStart]- $dipLocs[$dipBottomIdx] - $dipLocs[$dipEnd] size=",($dipLocs[$dipEnd] - $dipLocs[$dipStart]),"\n"; 
				#	print "diff=",($dipLocs[$dipBottomIdx] - $dipLocs[$dipBottomIdx-1]),"\n";
				#	}
				
				# Iterate $dipEnd from $dipBottomIdx+1 forwards until we reach a location $maxDipCenterSize/2 away or reach the end of the dip
				$dipEnd = $dipBottomIdx + 1;
				while($dipEnd<scalar(@dipCnts)-1 && $dipLocs[$dipEnd+1]-$dipLocs[$dipBottomIdx] <= ceil($maxDipCenterSize/2)) { 
					$dipEnd++;
					#if($curChr eq "chr18" && $curRegionID==159) { print "end: [$dipLocs[$dipStart] - $dipLocs[$dipBottomIdx] - $dipLocs[$dipEnd]] (#",($dipLocs[$dipEnd]-$dipLocs[$dipStart]),")\n"; }
				}
				
				
			}
			
			#print "dipCnts=",list2Str(\@dipCnts),"\n";
			#if($dipLocs[$dipEnd] - $dipLocs[$dipStart] > $maxDipCenterSize)
			#if($curChr eq "chr18" && $curRegionID==159)
			#{ print "#### Good dip, $curChr, regionID=$regionID, $dipLocs[$dipStart]- $dipLocs[$dipBottomIdx] - $dipLocs[$dipEnd] size=",($dipLocs[$dipEnd] - $dipLocs[$dipStart]),"\n"; }
			push(@{$allDips{$curChr}}, {dipSize         => $curDipSize, 
			                            dipCenter       => $dipLocs[$dipBottomIdx], 
			                            dipCenterHeight => $dipCnts[$dipBottomIdx], 
			                            dipStart        => $dipLocs[$dipStart], 
			                            dipEnd          => $dipLocs[$dipEnd],
			                            dipLocs         => \@dipLocs,
			                            dipCnts         => \@dipCnts});
			if($visualize) {
				$numDipsInRegion++;
				for(my $i=0; $i<scalar(@dipLocs); $i++)
				{ print $rout "$curChr\t$dipLocs[$i]\t$dipCnts[$i]\tDips\t$numDipsInRegion\n"; }
			}
		} else {
			#print "#### Dip too short\n";
		}

		#print $dips "$dipHeight\t$dipStart\t$dipEnd\n";
	} else {
		#print "#### Dip slope length too short, droppingSlopeCnt=$droppingSlopeCnt, risingSlopeCnt=$risingSlopeCnt\n";
	}
}

sub startRegion
{
	if($curRegionID!=-1 && $visualize) {
		#print "regionID=$regionID\n";
		system "mkdir -p $dipsFile.viz/$curChr";
		open($rout, ">$dipsFile.viz/$curChr/regionID_$curRegionID")  || die "ERROR opening file \"$dipsFile.viz/$curChr/regionID_$curRegionID\" for writing! $!"; 
		#print "regionID=$curRegionID\n";
		$numDipsInRegion=0;
	}	
}

sub endRegion
{
	if($numDipsInRegion>0 && $visualize) {
		close($rout);
		
		$ENV{DATA_PATH}="$dipsFile.viz/$curChr/regionID_$curRegionID"; 
		#system "Rscript --vanilla vizDips.R";
		system "/cygdrive/c/Program\\ Files/R/R-2.15.2/bin/x64/Rcmd.exe BATCH vizDips.R";
	}
	if($visualize) {
		system "rm -f $dipsFile.viz/$curChr/regionID_$curRegionID";
	}
}
