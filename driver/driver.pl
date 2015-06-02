#!/usr/bin/perl
use strict;
use warnings;

my $visualizeDips = 0;

#my $tgtState = 1;
my $windowSize = 25;
my $dipSizeThreshold = .4;
my $dipHeighAroundCenter = .2;
my $maxDipCenterSize = 200;
my $maxZeroes = 250;

my $startTime = time();
foreach my $slopeLength (2, 3, 4) {
#foreach my $slopeLength (4) {
	print "slopeLength=$slopeLength\n";
	my $workDir = "results.windowSize_$windowSize.slopeLength_$slopeLength.dipSizeThreshold_$dipSizeThreshold.dipHeighAroundCenter_$dipHeighAroundCenter.maxDipCenterSize_$maxDipCenterSize.maxZeroes_$maxZeroes";
	system "mkdir -p $workDir";

	foreach my $readsFName ("R_4sort.bed","2_3sort.bed","6_3sort.bed","G_4sort.bed") {
	#foreach my $readsFName ("G_4sort.bed") {
		print "    readsFName=$readsFName\n";
		print "    Moving Reads file \"$readsFName\"\n";
		if(!(-e "${readsFName}.moved")) { sys("./moveReads.pl $readsFName ${readsFName}.moved 100", 1, "    "); }
		
		foreach my $regionsFName ("R_dR_diffstates_250_25_4b","dR_dY_diffstates_250_25_4b","dY_G_diffstates_250_25_4b") {
		#foreach my $regionsFName ("dY_G_diffstates_250_25_4b") {
		# If the dips file has not yet been created
		if(!fileCreated("$workDir/dips.$readsFName.$regionsFName")) {
			sys("rm -r $workDir/*.$readsFName.$regionsFName", 1, "    ");
			sys("qsub -l qname=blelloch -A asccasc -l nodes=1 -l partition=$ENV{realMachine} -q pbatch -l walltime=5:00:00 -V -o $workDir/out.$readsFName.$regionsFName -j oe ./job.pl $workDir $slopeLength $readsFName $regionsFName $windowSize $dipSizeThreshold $dipHeighAroundCenter $maxDipCenterSize $maxZeroes $visualizeDips", 1, "        ");
		} }
	}
}
# Returns true iff the file exists has has size greater than 0
sub fileCreated
{
	my ($fName) = @_;

	return (-e $fName) && (-s $fName > 0);
}

sub sys
{
	my ($cmd, $verbose, $indent) = @_;
	print "${indent}$cmd\n";
	system $cmd;
}

