#!/usr/bin/perl

use strict;
use warnings;

my $samtools_executable = '/N/dc2/projects/RNAMap/raga/samtools/samtools';
my @queries = ('/N/dc2/projects/RNAMap/raga/MACS2/RK7-1.bam','/N/dc2/projects/RNAMap/raga/MACS2/RK7-2.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK7-3.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK7-4.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-1.bam','/N/dc2/projects/RNAMap/raga/MACS2/RK15-2.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-3.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-4.bam','/N/dc2/projects/RNAMap/raga/MACS2/RK16-1.bam','/N/dc2/projects/RNAMap/raga/MACS2/RK16-2.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-3.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-4.bam');
my @outfiles = ('/N/dc2/projects/RNAMap/raga/MACS2/RK7-1_sort.bam','/N/dc2/projects/RNAMap/raga/MACS2/RK7-2_sort.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK7-3_sort.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK7-4_sort.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-1_sort.bam','/N/dc2/projects/RNAMap/raga/MACS2/RK15-2_sort.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-3_sort.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-4_sort.bam','/N/dc2/projects/RNAMap/raga/MACS2/RK16-1_sort.bam','/N/dc2/projects/RNAMap/raga/MACS2/RK16-2_sort.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-3_sort.bam', '/N/dc2/projects/RNAMap/raga/MACS2/RK15-4_sort.bam');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$samtools_executable sort $queries[$i] > $outfiles[$i]";
}
