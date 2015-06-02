#!/usr/bin/perl

use strict;
use warnings;

my $bam = '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/bamToBed';
my @infiles = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-1.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-2.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-3.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-4.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-1.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-2.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-3.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-4.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-1.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-2.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-3.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-4.bam');
my @outfiles = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-1.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-2.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-3.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-4.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-1.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-2.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-3.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-4.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-1.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-2.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-3.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-4.bed');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$bam callpeak -i $infiles[$i] > $outfiles[$i]";
}
