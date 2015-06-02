#$ -S /usr/bin/perl

use strict;
use warnings;

my $samtools_executable = '/mnt/iscsi_speed/blelloch/Raga/samtools';
my @queries = ('/mnt/iscsi_speed/blelloch/Raga/samtools/R_8b.sam','/mnt/iscsi_speed/blelloch/Raga/samtools/dR_8b.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/dY_8b.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/G_8b.sam');
my @outfiles = ('/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/R_8b.bam','/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/dR_8b.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/dY_8b.bam', '/mnt/iscsi_speed/blelloch/Raga/BEDtools_bins/G_8b.bam');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$samtools_executable view -bS $queries[$i] > $outfiles[$i]";
}
