#$ -S /usr/bin/perl

use strict;
use warnings;

my $choosecolumns = '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/choosecolumns.pl';
#my $inFile = '/mnt/iscsi_speed/blelloch/Raga/MACS/8_1.bam';
#my $outFile = '/mnt/iscsi_speed/blelloch/Raga/MACS/8_4.bam';

my @inFile = ('/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_8bsort.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dR_8bsort.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dY_8bsort.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_8bsort.bed');
my @outFile = ('/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_8blite.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dR_8blite.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dY_8blite.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_8blite.bed');

for(my $i=0; $i<scalar(@inFile); $i++) {
	system "perl $choosecolumns $inFile[$i] $outFile[$i]";
}

my @newinFile = ('/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_8blite.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dR_8blite.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dY_8blite.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_8blite.bed');
my @newoutFile = ('/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_8blitesort.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dR_8blitesort.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dY_8blitesort.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_8blitesort.bed');

for(my $j=0; $j<scalar(@newinFile); $j++) {
	system "sort -k1,1 -k2,2g $newinFile[$j] > $newoutFile[$j]";
}