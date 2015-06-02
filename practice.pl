#!/usr/bin/perl
# Causes Perl to abort if there are any obvious mistakes in the script
use strict;
use warnings;

#create a list that contains numbers 1,3,5,7,9
#divide every number by 2 and print results

#my @numbers = (1,3,5,7,9);

#load a file and make a list from file
my @numbers=();

open(my $file, "<input.txt") || die "ERROR opening file \"input\" for reading! $!";

# Loop over the file one line at a time. Each time we see a line we increment the $numLines counter.
my $numLines = 0; # The number of lines starts at 0
#open(my $outfile, ">output");
# <> holds onto line breaks, so to get rid of it, use chomp
while(my $line=<$file>) {
	chomp $line;
	push (@numbers, $line);
	$numLines++; # Increment $numLines each time we reach a new line
}
#close($outfile);
close($file);


# Foreach is just for @lists
open(my $outfile, ">blah") || die "ERROR opening file \"blah\" for writing! $!";
foreach my $i (@numbers) 
	{$i=$i/2;
	print $outfile "$i\n";
	}	
close($outfile);
	
	

# access 50th line of $file
# file has been defined and opened

#my $numLines = 0; # The number of lines starts at 0
#while(my $line=<$file>) {
#	if ($numLines==49){
#	print $line;}
#	$numLines++; # Increment $numLines each time we reach a new line
#}	