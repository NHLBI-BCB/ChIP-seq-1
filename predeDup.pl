#!/usr/bin/perl
use strict;
use warnings;

my $workdir = '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/sort/'
my $workdir2 = '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/sort/'
my $deDup = '/N/dc2/projects/RNAMap/raga/chromhmm/ChromHMM/sort/deDup.pl';
my @queries = ("$workdir/RK1-1sort.bed","$workdir/RK1-3sort.bed","$workdir/RK1-4sort.bed","$workdir/RK2-1sort.bed","$workdir/RK2-2sort.bed","$workdir/RK2-3sort.bed","$workdir/RK3-1sort.bed","$workdir/RK3-2sort.bed","$workdir/RK3-3sort.bed","$workdir/RK3-4sort.bed");
my @outfiles = ("$workdir/RK1-1sort-dedup.bed","$workdir/RK1-3sort-dedup.bed","$workdir/RK1-4sort-dedup.bed","$workdir/RK2-1sort-dedup.bed","$workdir/RK2-2sort-dedup.bed","$workdir/RK2-3sort-dedup.bed","$workdir/RK3-1sort-dedup.bed","$workdir/RK3-2sort-dedup.bed","$workdir/RK3-3sort-dedup.bed","$workdir/RK3-4sort-dedup.bed");

for (my $i=0; $i<scalar(@queries); $i++) {
	system "perl deDup.pl $queries[$i] $outfiles[$i]";
}
