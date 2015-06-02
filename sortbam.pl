#!/usr/bin/perl

use strict;
use warnings;

my @queries = ('/N/dc2/projects/RNAMap/raga/newbam/FCKO-FlagRco.bam', '/N/dc2/projects/RNAMap/raga/newbam/E2-FlagRco.bam', '/N/dc2/projects/RNAMap/raga/newbam/FCKO-FlagdYco.bam', '/N/dc2/projects/RNAMap/raga/newbam/E2-FlagdYco.bam');
my @midfiles = ('/N/dc2/projects/RNAMap/raga/newbam/FCKO-FlagRco-sort.bam', '/N/dc2/projects/RNAMap/raga/newbam/E2-FlagRco-sort.bam', '/N/dc2/projects/RNAMap/raga/newbam/FCKO-FlagdYco-sort.bam', '/N/dc2/projects/RNAMap/raga/newbam/E2-FlagdYco-sort.bam');	
#my @endfiles = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-1_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-2_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-3_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-4_sort.bam,/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-1_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-2_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-3_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-4_sort.bam,/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK3-1_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK3-2_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK3-3_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK3-4_sort.bam');	
#my @outfiles = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-1.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-2.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-3.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-4.bg,/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-1.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-2.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-3.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK2-4.bg,/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK3-1.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK3-2.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK3-3.bg', '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK3-4.bg');	
#my $genome = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/mm10.txt');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "samtools sort $queries[$i] $midfiles[$i]";
}

