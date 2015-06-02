#!/usr/bin/perl

use strict;
use warnings;

my $peaks = ('/N/dc2/projects/RNAMap/raga/peaks2014/dYlocsold.txt');	
my $locations = ('/N/dc2/projects/RNAMap/raga/peaks2014/dYlocsnew.txt');	
#my @bedfiles = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-2.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-4.bed');	
my $perlfile = '/N/dc2/projects/RNAMap/raga/peaks2014/overlappeaks.pl';

system "ls -l $perlfile";
system "ls -l /N/dc2/projects/RNAMap/raga/peaks2014";

#for(my $i=0; $i<scalar(@bedfiles); $i++) {
system "$perlfile $peaks $locations";
#}

#./getNearbyReads.pl bedFile locations counts neighborhoodSize windowSize