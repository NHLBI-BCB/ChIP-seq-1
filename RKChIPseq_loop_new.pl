#!/usr/bin/perl
use strict;
use warnings;

my @queries = ('/N/dc2/projects/RNAMap/raga/fastq/RK9-1.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK9-2.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK9-3.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK9-4.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK10-1.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK10-2.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK10-3.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK10-4.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK11-1.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK11-2.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK11-3.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK11-4.fastq',);
my @outfiles = ('/N/dc2/projects/RNAMap/raga/fastq/RK9-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK9-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK9-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK9-4.sam','/N/dc2/projects/RNAMap/raga/fastq/RK10-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK10-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK10-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK10-4.sam','/N/dc2/projects/RNAMap/raga/fastq/RK11-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK11-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK11-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK11-4.sam',);
my $bowtie_executable = '/N/dc2/projects/RNAMap/raga/bowtie2-2.1.0/bowtie2';
my $genome = '/N/dc2/projects/RNAMap/raga/bowtie2-2.1.0/genomes/mm10';

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$bowtie_executable -p 4 -q -D 15 -R 2 -L 22 -i S,1,1.15 -k 1 $genome $queries[$i] -S $outfiles[$i]";
}
