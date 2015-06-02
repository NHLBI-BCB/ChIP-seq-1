#$ -S /usr/bin/perl

use strict;
use warnings;

my @filename = ("/mnt/iscsi_speed/blelloch/testdir/4_4asort.bed", "/mnt/iscsi_speed/blelloch/testdir/4_4esort.bed");
my $numParts = 10;
my $splitter_script = '/mnt/iscsi_speed/blelloch/testdir/splitter.pl';

# Foreach is just for @lists that you don't want to actually modify (eg. if you want to run a script for a list of files)
#foreach my $curFile (@filename) 
#{system "splitter.pl $curFile $numParts";}

for(my $i=0; $i<scalar(@filename); $i++) {
	system "perl $splitter_script $filename[$i] $numParts";
}
