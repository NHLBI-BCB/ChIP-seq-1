#$ -S /usr/bin/perl

use strict;
use warnings;

my $samtools_executable = '/mnt/iscsi_speed/blelloch/testdir/samtools';
my $query = '/mnt/iscsi_speed/blelloch/testdir/4_4e.sam';
my $outfile = '/mnt/iscsi_speed/blelloch/testdir/4_4e1.bam';

system "$samtools_executable view -bS $query > $outfile";
