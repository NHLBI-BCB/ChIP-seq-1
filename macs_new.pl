#!/usr/bin/perl

use strict;
use warnings;

my $macs_executable = '/N/dc2/projects/RNAMap/raga/MACS2_source/MACS2-2.0.10.20131216/bin/macs2';
my $control = ('/N/dc2/projects/RNAMap/raga/MACS2/RK7-1.bam');
my $ChIP = ('/N/dc2/projects/RNAMap/raga/MACS2/RK7-2.bam');

system "$macs_executable callpeak -t $ChIP -c $control -f BAM -g mm -n R_Flag -B -q 0.01";
