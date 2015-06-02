#!/usr/bin/perl

use strict;
use warnings;

my @queries = ('/N/dc2/projects/RNAMap/raga/newbed2/MN-dY-K4me1-Tamlong-sort.bg', '/N/dc2/projects/RNAMap/raga/newbed2/MN-dY-Tam-K4me1-n-sort.bg', '/N/dc2/projects/RNAMap/raga/newbed2/MN-dY-EtOH-K4me1-n-sort.bg', '/N/dc2/projects/RNAMap/raga/newbed2/MN-R-Tam-K4me1-n-sort.bg');
my @outfiles = ('/N/dc2/projects/RNAMap/raga/newbed2/MN-dY-K4me1-Tamlong-sort.bw', '/N/dc2/projects/RNAMap/raga/newbed2/MN-dY-Tam-K4me1-n-sort.bw', '/N/dc2/projects/RNAMap/raga/newbed2/MN-dY-EtOH-K4me1-n-sort.bw', '/N/dc2/projects/RNAMap/raga/newbed2/MN-R-Tam-K4me1-n-sort.bw');
#my @endfiles = ('/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK1-1_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK1-2_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK1-3_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK1-4_sort.bam,/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK2-1_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK2-2_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK2-3_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK2-4_sort.bam,/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK3-1_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK3-2_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK3-3_sort.bam', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK3-4_sort.bam');	
#my @outfiles = ('/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK1-1.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK1-2.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK1-3.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK1-4.bg,/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK2-1.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK2-2.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK2-3.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK2-4.bg,/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK3-1.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK3-2.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK3-3.bg', '/N/dc2/projects/RNAMap/raga/chromhmmnew/ChromHMM/RK3-4.bg');	
my $genome = ('/N/dc2/projects/RNAMap/raga/newbed2/mm10.chrom.sizes');
#my $exe = '/N/dc2/projects/RNAMap/raga/bedtools-2.17.0/bin/genomeCoverageBed'; 
#my @scalefac = (0.74, 0.53, 1, 0.51);

for(my $i=0; $i<scalar(@queries); $i++) {
	#system "samtools sort $queries[$i] $midfiles[$i]";
	system "bedGraphToBigWig $queries[$i] $genome -$outfiles[$i]";
}

