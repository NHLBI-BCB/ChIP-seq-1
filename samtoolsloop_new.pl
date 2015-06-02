#!/usr/bin/perl

use strict;
use warnings;

my $samtools_executable = '/N/dc2/projects/RNAMap/raga/samtools/samtools';
my @queries = ('/N/dc2/projects/RNAMap/raga/fastq/RK4-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK4-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK4-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK4-4.sam','/N/dc2/projects/RNAMap/raga/fastq/R5-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK5-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK5-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK5-4.sam','/N/dc2/projects/RNAMap/raga/fastq/RK6-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK6-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK6-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK6-4.sam');
my @outfiles = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-1.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-2.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-3.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK4-4.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/R5-1.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-2.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-3.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK5-4.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-1.bam','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-2.sam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-3.sam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK6-4.sam');     

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$samtools_executable view -bS $queries[$i] > $outfiles[$i]";
}
