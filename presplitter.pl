#$ -S /usr/bin/perl

use strict;
use warnings;

my @filename = ("/mnt/iscsi_speed/blelloch/RKBedfiles/2_1sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/2_2sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/2_3sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/2_4sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/4_1sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/4_2sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/4_3sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/4_4sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/6_1sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/6_2sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/6_3sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/6_4sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/8_1sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/8_2sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/8_3sort.bed", "/mnt/iscsi_speed/blelloch/RKBedfiles/8_4sort.bed");
my $numParts = 10;
my $splitter_script = '/mnt/iscsi_speed/blelloch/RKBedfiles/splitter.pl';

# Foreach is just for @lists that you don't want to actually modify (eg. if you want to run a script for a list of files)
#foreach my $curFile (@filename) 
#{system "splitter.pl $curFile $numParts";}

for(my $i=0; $i<scalar(@filename); $i++) {
	system "perl $splitter_script $filename[$i] $numParts";
}
