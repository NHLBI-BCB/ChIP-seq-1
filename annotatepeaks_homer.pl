#$ -S /usr/bin/perl

use strict;
use warnings;

my @queries = ('/mnt/iscsi_speed/blelloch/Raga/HOMER/2_1sort.bed','/mnt/iscsi_speed/blelloch/Raga/HOMER/6_1sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/2_2sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/6_2sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/2_3sort.bed','/mnt/iscsi_speed/blelloch/Raga/HOMER/6_3sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/2_4sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/6_4sort.bed','/mnt/iscsi_speed/blelloch/Raga/HOMER/4_1sort.bed','/mnt/iscsi_speed/blelloch/Raga/HOMER/8_1sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/4_2sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/8_2sort.bed','/mnt/iscsi_speed/blelloch/Raga/HOMER/4_3sort.bed','/mnt/iscsi_speed/blelloch/Raga/HOMER/8_3sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/4_4sort.bed', '/mnt/iscsi_speed/blelloch/Raga/HOMER/8_4sort.bed');
my @outdirs = ('/mnt/iscsi_speed/blelloch/Raga/HOMER/dR_H3K4me1/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dY_H3K4me1/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dR_H3K4me3/', '/mnt/iscsi_speed/blelloch/Raga/HOMER/dY_H3K4me3/', '/mnt/iscsi_speed/blelloch/Raga/HOMER/dR_H3K27ac/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dY_H3K27ac/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dR_H3K27me3/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dY_H3K27me3/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dR_IgG/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dY_IgG/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dR_p300/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dY_p300/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dR_Oct4/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dY_Oct4/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dR_Pol2/','/mnt/iscsi_speed/blelloch/Raga/HOMER/dY_Pol2/');	
my $makeTagDirectories = '/mnt/iscsi_speed/blelloch/Raga/HOMER/bin/annotatePeaks.pl';

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$makeTagDirectories $outdirs[$i] $queries[$i] -format bed -forceBED";
}

