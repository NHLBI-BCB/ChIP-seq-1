#!/usr/bin/perl

use strict;
use warnings;

my @counts = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/Rpeaks_EK4me1.txt','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/Rpeaks_TK4me1.txt');	
my $locations = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/R_Flag_peaks_lite.txt');	
my @bedfiles = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-2.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-4.bed');	
my $perlfile = '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/getNearbyReads.pl';

for(my $i=0; $i<scalar(@bedfiles); $i++) {
	system "$perlfile $bedfiles[$i] $locations $counts[$i] 5000 200";
}

#./getNearbyReads.pl bedFile locations counts neighborhoodSize windowSize