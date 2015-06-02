#$ -S /usr/bin/perl

use strict;
use warnings;

#my $query = '/mnt/iscsi_speed/blelloch/RKBedfiles/2_2.bed';
#my $outfile = '/mnt/iscsi_speed/blelloch/RKBedfiles/2_2sort.bed';

my @queries = ('/mnt/iscsi_speed/blelloch/testdir/4_4a.bed', '/mnt/iscsi_speed/blelloch/testdir/4_4e.bed');
my @outfiles = ('/mnt/iscsi_speed/blelloch/testdir/4_4asort.bed', '/mnt/iscsi_speed/blelloch/testdir/4_4esort.bed');

for(my $i=0; $i<scalar(@queries); $i++) {
	system "sort -k1,1 -k2,2g $queries[$i] > $outfiles[$i]";
}