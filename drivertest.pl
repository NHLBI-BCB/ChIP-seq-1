#$ -S /usr/bin/perl
use strict;
use warnings;

my $visualizeDips = 0;

#my $tgtState = 1;
my $windowSize = 25;
my $dipSizeThreshold = .4;
my $dipHeighAroundCenter = .2;
my $maxDipCenterSize = 200;
my $maxZeroes = 250;
my $job = '/mnt/iscsi_speed/blelloch/Raga/ChromHMM/dips/job.pl';

my $startTime = time();
foreach my $slopeLength (2) {
#foreach my $slopeLength (4) {
	print "slopeLength=$slopeLength\n";
	my $workDir = "/mnt/iscsi_speed/blelloch/Raga/ChromHMM/dips/results.windowSize_$windowSize.slopeLength_$slopeLength.dipSizeThreshold_$dipSizeThreshold.dipHeighAroundCenter_$dipHeighAroundCenter.maxDipCenterSize_$maxDipCenterSize.maxZeroes_$maxZeroes";
	system "mkdir -p $workDir";

	foreach my $readsFName ("2_3sort.bed") {
	#foreach my $readsFName ("G_4sort.bed") {
		print "    readsFName=$readsFName\n";
		print "    Moving Reads file \"$readsFName\"\n";
		if(!(-e "${readsFName}.moved")) { sys("./moveReads.pl $readsFName ${readsFName}.moved 100", 1, "    "); }
		
		foreach my $regionsFName ("R_dR_diffstates_250_25_4b") {
		#foreach my $regionsFName ("dY_G_diffstates_250_25_4b") {
		# If the dips file has not yet been created
		if(!fileCreated("$workDir/dips.$readsFName.$regionsFName")) {
			sys("rm -fr $workDir/*.$readsFName.$regionsFName", 1, "    ");
			sys("qsub -l qname=blelloch -V -e /$workDir -o $workDir/out.$readsFName.$regionsFName -j y perl $myjob $workDir $slopeLength $readsFName $regionsFName $windowSize $dipSizeThreshold $dipHeighAroundCenter $maxDipCenterSize $maxZeroes $visualizeDips", 1, "        ");
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

