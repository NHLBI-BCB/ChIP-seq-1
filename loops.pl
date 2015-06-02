#!/usr/bin/perl
# Causes Perl to abort if there are any obvious mistakes in the script
use strict;

my @filename = ("sdfaf.bed", "awekfja.bed", "sljiejf.bed");
my $numParts = 10;

# Different variants of loops

# Foreach is just for @lists that you don't want to actually modify (eg. if you want to run a script for a list of files)
foreach my $curFile (@filename) 
{system "splitter.pl $curFile $numParts";}

for(my $i=0; $i<scalar(@filename); $i++) {
	my $curFile = $filename[$i];
	print "$i: $curFile\n";
	...
}

my $i=0;
while($i<scalar(@filename)) {
	my $curFile = $filename[$i];
	
	...
	
	$i++;
}

# If want to do the first iteration and then check afterwards
my $i=0;
do {
	my $curFile = $filename[$i];
	
	...
	
	$i++;
} while($i<scalar(@filename));

# Reading in a file line by line using a for or a while loop, while counting line numbers
for(my $curLine=0; my $line=<$file>; $curLine++) {
	
}

my $curLine=0;
while(my $line=<$file>) {
	
	$curLine++;
}

