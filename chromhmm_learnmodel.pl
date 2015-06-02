#!/usr/bin/perl

use strict;
use warnings;

my $chromhmm = '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/ChromHMM.jar';
my $java = '/N/dc2/projects/RNAMap/raga/chromhmm/jre1.7.0_45/bin/java';
my $list = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/listoffiles');
my $binin = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/K4me1_K27a_K27me3_p300/');
my $out = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/OUTPUT_K4me1_K27a_K27me3_p300/');
my $sizes = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/mm10.chrom.sizes');

system "$java -Xmx200M -jar $chromhmm LearnModel $binin $out 6 mm10";

