#!/usr/bin/perl

use strict;
use warnings;

my $samtools_executable = '/N/dc2/projects/RNAMap/raga/samtools/samtools';
my @queries1 = ('/N/dc2/projects/RNAMap/raga/newbam/FCKO-FlagR.bam','/N/dc2/projects/RNAMap/raga/newbam/E2-FlagR.bam','/N/dc2/projects/RNAMap/raga/newbam/FCKO-FlagdY.bam','/N/dc2/projects/RNAMap/raga/newbam/E2-FlagdY.bam');
my @queries2 = ('/N/dc2/projects/RNAMap/raga/newbam/R-FCKO.bam','/N/dc2/projects/RNAMap/raga/newbam/R-E2.bam','/N/dc2/projects/RNAMap/raga/newbam/dY-FCKO.bam','/N/dc2/projects/RNAMap/raga/newbam/dY-E2.bam');
my @outfiles = ('/N/dc2/projects/RNAMap/raga/newbam/FCKO-FlagRco.bam','/N/dc2/projects/RNAMap/raga/newbam/E2-FlagRco.bam','/N/dc2/projects/RNAMap/raga/newbam/FCKO-FlagdYco.bam','/N/dc2/projects/RNAMap/raga/newbam/E2-FlagdYco.bam');

for(my $i=0; $i<scalar(@queries1); $i++) {
	system "$samtools_executable merge $outfiles[$i] $queries1[$i] $queries2[$i]";
}
