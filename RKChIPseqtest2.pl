#$ -S /usr/bin/perl

use strict;
use warnings;

my $bowtie_executable = '/mnt/iscsi_speed/blelloch/bowtie2/bowtie2';
my $genome = '/mnt/iscsi_speed/blelloch/bowtie2/genomes/mm10';
my $query = '/mnt/iscsi_speed/blelloch/RK_2012/4_4.fastq';
my $outfile = '/mnt/iscsi_speed/blelloch/RK_2012/4_4c.sam';


#system "$bowtie_executable -p 4 -q -N 0 -k 1 $genome $query -S $outfile";
system "$bowtie_executable -p 4 -q -D 15 -R 2 -N 0 -L 20 -i S,1,0.75 $genome $query -S $outfile";



#my @files = ('1_1.fastq', '2,,,);

#my $abc;

#foreach $abc(@files){
	#my $bowtie_executable = '/mnt/iscsi_speed/blelloch/bowtie-0.12.8/bowtie';
	#my $genome = '/mnt/iscsi_speed/blelloch/bowtie-0.12.8/genomes/mirna';
	#my $query = '/mnt/iscsi_speed/blelloch/DRC_seq_2012/' . $abc;
	#my $outfile = '/mnt/iscsi_speed/blelloch/DRC_seq_2012/' . $abc . '.map';
#}


#system "$bowtie_executable -p 4 -f -v 0 -k 5 -m 5 $genome $query $outfile";



#$ -S /usr/bin/perl

