#$ -S /usr/bin/perl

use strict;
use warnings;

my @queries = ('/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_8b.fastq','/mnt/iscsi_speed/blelloch/Raga/RK_2013/dR_8b.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/dY_8b.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_8b.fastq');
my @outfiles = ('/mnt/iscsi_speed/blelloch/Raga/samtools/R_8b.sam','/mnt/iscsi_speed/blelloch/Raga/samtools/dR_8b.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/dY_8b.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/G_8b.sam');	
my $bowtie_executable = '/mnt/iscsi_speed/blelloch/bowtie2/bowtie2';
my $genome = '/mnt/iscsi_speed/blelloch/bowtie2/genomes/mm10';

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$bowtie_executable -p 4 -q -D 15 -R 2 -L 22 -i S,1,1.15 -k 1 $genome $queries[$i] -S $outfiles[$i]";
}
