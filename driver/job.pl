#!/usr/bin/perl
use strict;
use warnings;

if(scalar(@ARGV)!=10) { die "Usage: job.pl workDir slopeLength readsFName regionsFName windowSize dipSizeThreshold dipHeighAroundCenter maxDipCenterSize maxZeroes visualizeDips"; }
my ($workDir, $slopeLength, $readsFName, $regionsFName, $windowSize, $dipSizeThreshold, $dipHeighAroundCenter, $maxDipCenterSize, $maxZeroes, $visualizeDips) = @ARGV;

my $label = "$readsFName.$regionsFName";

my $startTime = time();
print "        regionsFName=$regionsFName\n";
print "            Counting reads from \"$readsFName\" against regions in \"$regionsFName\"\n";
sys("./countMatchReads.pl $regionsFName ${readsFName}.moved $workDir/counts.$label", 1, "            ");
my $curTime = time();
print "            Windowing counts, elapsed=",($curTime-$startTime),"\n";
sys("./windowCountsDisj.pl $workDir/counts.$label $workDir/winCounts.$label $windowSize 0", 1, "            ");
$curTime = time();
print "            Searching for dips, elapsed=",($curTime-$startTime),"\n";
sys("./findDips.pl $workDir/winCounts.$label $workDir/dips.$label $slopeLength $dipSizeThreshold $dipHeighAroundCenter $maxDipCenterSize $maxZeroes $visualizeDips", 1, "            ");

sub sys
{
	my ($cmd, $verbose, $indent) = @_;
	print "${indent}$cmd\n";
	system $cmd;
}

