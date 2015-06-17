#!/usr/bin/perl

use strict;
use warnings;


my $in = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-1.bg','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-2.bg');
my $out = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-1.bw','/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/RK1-2.bw');
my $sizes = ('/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/mm10.chrom.sizes');

system "bedGraphToBigWig $in $sizes $out;

bedGraphToBigWig in.bedGraph chrom.sizes out.bw

##raga##