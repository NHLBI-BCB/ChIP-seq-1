#$ -S /usr/bin/perl

use strict;
use warnings;

#my $query = '/mnt/iscsi_speed/blelloch/RKBedfiles/2_2.bed';
#my $outfile = '/mnt/iscsi_speed/blelloch/RKBedfiles/2_2sort.bed';

my @queries = ('/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_8b.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dR_8b.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dY_8b.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_8b.bed');
my @outfiles = ('/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/R_8bsort.bed','/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dR_8bsort.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/dY_8bsort.bed', '/mnt/iscsi_speed/blelloch/Raga/Bedfiles2/G_8bsort.bed');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "sort -k1,1 -k2,2g $queries[$i] > $outfiles[$i]";
}