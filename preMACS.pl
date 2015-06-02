#$ -S /usr/bin/perl

use strict;
use warnings;

my $setup = '/mnt/iscsi_speed/blelloch/MACS/MACS-1.4.2/setup.py';

system "python $setup install";
