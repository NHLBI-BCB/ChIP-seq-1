#$ -S /usr/bin/perl

use strict;
use warnings;

my @queries = ('/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_1.fastq','/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_2.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_3.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_4.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_5.fastq','/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_6.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_7.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/R_8.fastq','/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_1.fastq','/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_2.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_3.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_4.fastq','/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_5.fastq','/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_6.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_7.fastq', '/mnt/iscsi_speed/blelloch/Raga/RK_2013/G_8.fastq');
my @outfiles = ('/mnt/iscsi_speed/blelloch/Raga/samtools/R_1.sam','/mnt/iscsi_speed/blelloch/Raga/samtools/R_2.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/R_3.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/R_4.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/R_5.sam','/mnt/iscsi_speed/blelloch/Raga/samtools/R_6.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/R_7.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/R_8.sam','/mnt/iscsi_speed/blelloch/Raga/samtools/G_1.sam','/mnt/iscsi_speed/blelloch/Raga/samtools/G_2.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/G_3.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/G_4.sam','/mnt/iscsi_speed/blelloch/Raga/samtools/G_5.sam','/mnt/iscsi_speed/blelloch/Raga/samtools/G_6.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/G_7.sam', '/mnt/iscsi_speed/blelloch/Raga/samtools/G_8.sam');	
my $bowtie_executable = '/mnt/iscsi_speed/blelloch/bowtie2/bowtie2';
my $genome = '/mnt/iscsi_speed/blelloch/bowtie2/genomes/mm10';

for(my $i=0; $i<scalar(@queries); $i++) {
	system "$bowtie_executable -p 4 -q -D 15 -R 2 -L 22 -i S,1,1.15 -k 1 $genome $queries[$i] -S $outfiles[$i]";
}
