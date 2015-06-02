#!/usr/bin/perl

use strict;
use warnings;

my $transstates = '/N/dc2/projects/RNAMap/raga/states/transHistogram.pl';
my @from = ('/N/dc2/projects/RNAMap/raga/states/RE_6_dense.bed');
my @to = ('/N/dc2/projects/RNAMap/raga/states/RT_6_dense.bed');
my @outfiles = ('/N/dc2/projects/RNAMap/raga/states/RE_vs_RT_states');     

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$transstates $from[$i] $to[$i] $outfiles 0";
}
#0 or 1 for verbose