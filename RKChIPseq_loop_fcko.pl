#!/usr/bin/perl
use strict;
use warnings;

my @queries = ('/N/dc2/projects/RNAMap/raga/fastq/R-FCKO.fastq','/N/dc2/projects/RNAMap/raga/fastq/dY-FCKO.fastq');
my @outfiles = ('/N/dc2/projects/RNAMap/raga/fastq/R-FCKO.sam','/N/dc2/projects/RNAMap/raga/fastq/dY-FCKO.sam');
my $bowtie_executable = '/N/dc2/projects/RNAMap/raga/bowtie2-2.1.0/bowtie2';
my $genome = '/N/dc2/projects/RNAMap/raga/bowtie2-2.1.0/genomes/mm10';

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$bowtie_executable -p 4 -q -D 15 -R 2 -L 22 -i S,1,1.15 -k 1 $genome $queries[$i] -S $outfiles[$i]";
}
