#!/usr/bin/perl
#This script echos the job array element that has been passed in

use strict;
my $pbs_array_id = shift @ARGV;
my $experimentID = $pbs_array_id;
my $experimentName = `head -n $pbs_array_id job.conf | tail -n1`;
my $experimentOut = $experimentName '_dedup';

system "samtools rmdup $experimentName $experimentOut";
