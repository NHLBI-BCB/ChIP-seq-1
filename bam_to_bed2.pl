#$ -S /usr/bin/perl

use strict;
use warnings;

my $bamtobed_executable = '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/bamToBed';
my @queries = ('/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_8b.bam','/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/dR_8b.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/dY_8b.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_8b.bam');
my @outfiles = ('/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_8b.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dR_8b.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dY_8b.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_8b.bed');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$bamtobed_executable -i $queries[$i] > $outfiles[$i]";
}
