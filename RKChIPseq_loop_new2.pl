#!/usr/bin/perl
use strict;
use warnings;

my @queries = ('/N/dc2/projects/RNAMap/raga/fastq/RK12-1.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK12-2.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK12-3.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK12-4.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK13-1.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK13-2.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK13-3.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK13-4.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK14-1.fastq','/N/dc2/projects/RNAMap/raga/fastq/RK14-2.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK14-3.fastq', '/N/dc2/projects/RNAMap/raga/fastq/RK14-4.fastq',);
my @outfiles = ('/N/dc2/projects/RNAMap/raga/fastq/RK12-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK12-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK12-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK12-4.sam','/N/dc2/projects/RNAMap/raga/fastq/RK13-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK13-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK13-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK13-4.sam','/N/dc2/projects/RNAMap/raga/fastq/RK14-1.sam','/N/dc2/projects/RNAMap/raga/fastq/RK14-2.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK14-3.sam', '/N/dc2/projects/RNAMap/raga/fastq/RK14-4.sam',);
my $bowtie_executable = '/N/dc2/projects/RNAMap/raga/bowtie2-2.1.0/bowtie2';
my $genome = '/N/dc2/projects/RNAMap/raga/bowtie2-2.1.0/genomes/mm10';

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$bowtie_executable -p 4 -q -D 15 -R 2 -L 22 -i S,1,1.15 -k 1 $genome $queries[$i] -S $outfiles[$i]";
}
