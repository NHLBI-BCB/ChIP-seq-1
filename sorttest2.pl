#!/usr/bin/perl

use strict;

my @array = ( 
   "kyy1         x753y420 31082010 07:01:11", 
   "exr1         x831y444 31082010 07:43:45", 
   "eef1         x717y532 31082010 07:30:17", 
   "bab3         x789y486 31082010 08:08:56", 
   "sam1        x1017y200 31082010 07:25:18", 
   "jmd2         x789y466 31082010 07:38:22", 
   "baa3cqc      x720y440 31082010 07:26:37"
);

# Sort by first column - login name
my @sortedName = sort { (split ' ', $a)[0] cmp (split ' ', $b)[0] } @array;

# Sort by second column - SKU number
my @sortedSkno = sort { (split ' ', $a)[1] cmp (split ' ', $b)[1] } @array;

# Sort by third - date - and fourth - time - column combined!
my @sortedTime = sort { (split ' ', $a)[2].(split ' ', $a)[3] cmp (split ' ', $b)[2].(split ' ', $b)[3] } @array;

print "Array\n";
print join( "\n", @array )."\n\n";

print "Sort Name\n";
print join( "\n", @sortedName )."\n\n";

print "Sort Skno\n";
print join( "\n", @sortedSkno )."\n\n";

print "Sort Date\n";
print join( "\n", @sortedTime )."\n\n";