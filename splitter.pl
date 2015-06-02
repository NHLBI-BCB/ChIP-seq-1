#!/usr/bin/perl
# Causes Perl to abort if there are any obvious mistakes in the script
use strict;

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 2) { die "Usage: splitter.pl filename number_of_parts"; }
# ALTERNATE: (scalar(@ARGV) == 2) || die "Usage: splitter.pl filename number_of_parts";
# double vertical line means OR (i.e. if whatever before double line is not true)

# Save the arguments into meaningfully-named variables
my $filename = $ARGV[0];
my $numParts = $ARGV[1];

# Compute the number of lines in the file

# Open the file for reading. $file is handle to the opened file and "<" means "for reading".
open(my $file, "<$filename") || die "ERROR opening file \"$filename\" for reading! $!";

# Loop over the file one line at a time. Each time we see a line we increment the $numLines counter.
my $numLines = 0; # The number of lines starts at 0
while(<$file>) {
	$numLines++; # Increment $numLines each time we reach a new line
}
#while you can see the next line of $file, add 1 to $numLines
# Close the file handle
close($file);

# Now compute the number of lines we'll place in each part (this is a real number, not an integer)
my $linesPerPart = $numLines / $numParts;

# Open the file again, except this time we'll also write its lines out in chunks of $linesPerPart
open(my $file, "<$filename") || die "ERROR opening file \"$filename\" for reading! $!";
my $outfile; # Handle to the current output file. There will be several of these files.

my $curLine=0; # The current line in the file, starting at 0.
my $nextChunkStart=0; # The line at which the next chunk will start. This is a real number 
                      # that is a multiple of $linesPerPart.
my $chunkID=0; # The id of the current chunk, incremented each time we start writing a new chunk.
# Loop over the file. This time we store the current line in variable $line.
while(my $line=<$file>) {

   # If we're at or past the starting line of the next line block
	if($curLine >= $nextChunkStart) {
		# If $outfile currently refers to a valid file, close it first
		if($outfile) { close($outfile); }
		
		# Open the next output file for writing. ">" meand "for writing".
		# Note that we don't say "my" since $outfile has already been declared with "my".
		open($outfile, ">${filename}.$chunkID.bed") || die "ERROR opening file \"${filename}.$chunkID\" for writing! $!";
		#curly brackets define edges of variable section of the output filename
		
		# Increment the chunk ID number to refer to the next chunk
		$chunkID++;
		# Advance $nextChunkStart to hold the starting line of the next chunk
		$nextChunkStart = $nextChunkStart + $linesPerPart; #$nextChunkStart += $linesPerPart
	}
	
	# Write out the current line from $file to $outfile
	print $outfile $line;
	
	$curLine++; # Increment $curLine each time we reach a new line
}


# If the file for the last chunk is still open (must be true if the input file had at least 1 line), close it
if($outfile) { close($outfile); }

# Close the file handle
close($file);