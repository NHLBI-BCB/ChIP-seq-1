#$ -S /usr/bin/perl
use strict;
use warnings;

my $visualizeDips = 0;

my $tgtState = 1;
my $windowSize = 25;
my $dipSizeThreshold = .4;
my $dipHeighAroundCenter = .2;
my $maxDipCenterSize = 200;
my $maxZeroes = 250;

my $movereads = '/mnt/iscsi_speed/blelloch/Raga/ChromHMM/dips/moveReads.pl';
my $countmatch = '/mnt/iscsi_speed/blelloch/Raga/ChromHMM/dips/countMatchReads.pl';
my $windowcount = '/mnt/iscsi_speed/blelloch/Raga/ChromHMM/dips/windowCountsDistj.pl';
my $finddips = '/mnt/iscsi_speed/blelloch/Raga/ChromHMM/dips/findDips.pl';

foreach my $slopeLength (2, 3, 4) {
	my $workDir = "results.state_$tgtState.windowSize_$windowSize.slopeLength_$slopeLength.dipSizeThreshold_$dipSizeThreshold.dipHeighAroundCenter_$dipHeighAroundCenter.maxDipCenterSize_$maxDipCenterSize.maxZeroes_$maxZeroes";
	system "mkdir -p $workDir";

	foreach my $readsFName ("R_4sort.bed","2_3sort.bed") {
		print "Moving Reads file \"$readsFName\"\n";
		system "perl $movereads $readsFName $workDir/${readsFName}.moved 100";
		
		foreach my $regionsFName ("R_dR_diffstates_1000_500_4b","R_dR_diffstates_1000_500_4a") {
			print "    Counting reads from \"$readsFName\" against regions in \"$regionsFName\"\n";
			system "perl $countmatch $regionsFName $workDir/${readsFName}.moved $workDir/counts $tgtState";
			print "    Windowing counts\n";
			system "perl $windowcount $workDir/counts $workDir/winCounts $windowSize 0";
			print "    Searching for dips\n";
			system "perl $finddips $workDir/winCounts $workDir/dips.$readsFName.$regionsFName.state_$tgtState $slopeLength $dipSizeThreshold $dipHeighAroundCenter $maxDipCenterSize $maxZeroes $visualizeDips";
			#system "mv $workDir/dips.$readsFName.$regionsFName.state_$tgtState .";
		}
	}
}
