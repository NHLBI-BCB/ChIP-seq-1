#!/usr/bin/perl

use strict;
use warnings;

my @queries = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-2.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-3.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-4.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-1.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-2.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-3.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-4.bed');
my @outfiles = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-2_sort.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-3_sort.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-4_sort.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-1_sort.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-2_sort.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-3_sort.bed','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-4_sort.bed');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "./sort -k1,1 -k2,2g $queries[$i] > $outfiles[$i]";
}

