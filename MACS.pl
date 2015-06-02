#$ -S /usr/bin/perl

#system "pwd";

use strict;
use warnings;

my $MACS_executable = '/mnt/iscsi_speed/blelloch/apps/MACS/bin/macs14';
my $control = '/mnt/iscsi_speed/blelloch/Raga/MACS/R_1.bam';
my $expt = '/mnt/iscsi_speed/blelloch/Raga/MACS/R_5.bam';

#my @control = ('/mnt/iscsi_speed/blelloch/RKBedfiles/2_1.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/2_2.bed','/mnt/iscsi_speed/blelloch/RKBedfiles/2_3.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/2_4.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/4_1.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/4_2.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/4_3.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/4_4.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/6_1.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/6_2.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/6_3.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/6_4.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/8_1.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/8_2.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/8_3.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/8_4.bed');
#my @outfiles = ('/mnt/iscsi_speed/blelloch/RKBedfiles/2_1sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/2_2sort.bed','/mnt/iscsi_speed/blelloch/RKBedfiles/2_3sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/2_4sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/4_1sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/4_2sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/4_3sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/4_4sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/6_1sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/6_2sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/6_3sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/6_4sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/8_1sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/8_2sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/8_3sort.bed', '/mnt/iscsi_speed/blelloch/RKBedfiles/8_4sort.bed');

system "$MACS_executable -t $expt -c $control -f BAM -g mm h --name='/mnt/iscsi_speed/blelloch/MACS/dY_Pol2' test -w";
#system "ls -l";  

macs14 -t 1_2.bam -c R_1.bam -f BAM -g mm h --name='/mnt/iscsi_speed/blelloch/Raga/MACS/K4me3_R_/R_K4me3' test -w