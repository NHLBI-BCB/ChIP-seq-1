#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Carp;

require "common.pl";

# Given a file of the counts of reads within various genome regions (named $countsFile), formatted as:
#    chromosome locationIndex countAtLocation regionID
# Windows the counts into disjoint $windowSize windows that start and end at genome locations that are evenly divisible 
# by $windowSize and emits a file (named $windowedCntsFile) that contains for each region and window the total number of 
# reads, formatted as:
#    chromosome windowCenterLocation avgCountInWindow regionID
# Further if the $visualize argument is set to non-zero, runs vizCountsOneRegion.R to visualize the windowed counts 
# within each region, saving the result into files $windowedCntsFile.regionID_$curRegionID.png.

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 4) { die "Usage: windowCountsDisj.pl countsFile windowedCntsFile windowSize visualize"; }
my ($countsFile, $windowedCntsFile, $windowSize, $visualize) = @ARGV;

open(my $counts, "<$countsFile")  || die "ERROR opening file \"$countsFile\" for reading! $!"; 
<$counts>; # Skip the header

open(my $out, ">$windowedCntsFile")  || die "ERROR opening file \"$windowedCntsFile\" for writing! $!"; 
print $out "Chr\tIndex\tCount\tregionID\n";

my $cntLNum=2;
my $curWin=0;
my $curWinSum=0; # The sum of all the counts in the current window
my $curWinStart=-1; # The starting point of the current window
my $winCount=0; # The number of lines read within a window
my $curChr = "";
my $curRegionID=-1;
my $rout;
while(my $line = <$counts>) {
	chomp $line;
	
	my @data = split(/\s+/, $line);
	if(scalar(@data)!=4) { die "ERROR in \"$countsFile\":$cntLNum expected 4 fields!"; }
	my ($chr, $idx, $cnt, $regionID) = @data;
	
	# If we've reached a new chromosome reset reading state
	if($curChr ne $chr) {
		endRegion();
		
		$curChr = $chr;
		$curWinSum=0;
		$winCount = 1;
		$curWinStart=-1; 
		$curRegionID=-1;
	}
	
	if($regionID!=$curRegionID) {
		endRegion();
		$curRegionID=$regionID;
		startRegion();
	}
	# If we're starting a new window, reset the current window info
	#print "idx=$idx, windowSize=$windowSize, ",int($idx/$windowSize)*$windowSize," != $curWinStart\n";
	if(int($idx/$windowSize)*$windowSize != $curWinStart) {
		# If a prior window has completed, print it out
		if($curWinStart != -1) { 
			if($winCount > $windowSize) { die "ERROR: winCount($winCount) > windowSize($windowSize)!"; }
			print $out "$curChr\t",($curWinStart + $windowSize/2),"\t$curWinSum\t$regionID\n";
			if($visualize)
			{ print $rout "$curChr\t",($curWinStart + $windowSize/2),"\t$curWinSum\n"; }
		}
		
		$curWinSum = $cnt;
		$winCount = 1;
		$curWinStart = int($idx/$windowSize)*$windowSize;
	} else {
		#print "winCount=$winCount, curWinSum=$curWinSum, cnt=$cnt\n";
		$curWinSum += $cnt;
		$winCount++;
	}
	
	$cntLNum++;
}

# If the end of the chromosome had an incomplete window, print it out
if($curWinStart != -1) { 
	if($winCount > $windowSize) { die "ERROR: winCount($winCount) > windowSize($windowSize)!"; }
	print $out "$curChr\t",($curWinStart + $windowSize/2),"\t$curWinSum\t$curRegionID\n"; 
	if($visualize)
	{ print $rout "$curChr\t",($curWinStart + $windowSize/2),"\t$curWinSum\n"; }
}

endRegion();

close($counts);
close($out);

sub startRegion
{
	if($visualize) {
		#print "regionID=$regionID\n";
		open($rout, ">$windowedCntsFile.regionID_$curRegionID")  || die "ERROR opening file \"$windowedCntsFile.regionID_$curRegionID\" for writing! $!"; 
		print "regionID=$curRegionID\n";
	}	
}

sub endRegion
{
	if($curRegionID!=-1 && $visualize) { 
		close($rout);
		$ENV{DATA_PATH}="$windowedCntsFile.regionID_$curRegionID"; 
		system "/cygdrive/C/Program\\ Files/R/R-2.15.2/bin/x64/Rcmd.exe BATCH vizCountsOneRegion.R";	
	}
}