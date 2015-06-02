#$ -S /usr/bin/perl

use strict;
use warnings;

my $readcount = '/mnt/iscsi_speed/blelloch/Raga/readcount/readGeneCount.pl';
my $genes = '/mnt/iscsi_speed/blelloch/Raga/readcount/mm10_refseq_strandsort';
#my $outFile = '/mnt/iscsi_speed/blelloch/Raga/MACS/8_4.bam';

my @inFile = ('/mnt/iscsi_speed/blelloch/Raga/readcount/4_1litesort.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/4_4litesort.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/8_1litesort.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/8_4litesort.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/R_1litesort.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/R_8litesort.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/G_1litesort.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/G_8litesort.bed');
my @outFile = ('/mnt/iscsi_speed/blelloch/Raga/readcount/4_1readcount.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/4_4readcount.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/8_1readcount.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/8_4readcount.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/R_1readcount.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/R_8readcount.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/G_1readcount.bed','/mnt/iscsi_speed/blelloch/Raga/readcount/G_8readcount.bed');
for(my $i=0; $i<scalar(@inFile); $i++) {
	system "perl $readcount $genes $inFile[$i] $outFile[$i]";
}
 