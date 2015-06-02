#$ -S /usr/bin/perl

use strict;
use warnings;

my $bamtobed_executable = '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/bamToBed';
my @queries = ('/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_1.bam','/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_2.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_3.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_4.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_5.bam','/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_6.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_7.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_8.bam','/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_1.bam','/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_2.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_3.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_4.bam','/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_5.bam','/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_6.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_7.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_8.bam');
my @outfiles = ('/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_1.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_2.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_3.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_4.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_5.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_6.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_7.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_8.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_1.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_2.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_3.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_4.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_5.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_6.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_7.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_8.bed');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$bamtobed_executable -i $queries[$i] > $outfiles[$i]";
}
