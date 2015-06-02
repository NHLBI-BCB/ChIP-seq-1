#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Carp;

# Given an input file in format "$chrom $start $stop $state *" with a header
#    ASSUMPTION: [start - stop] REGIONS ARE ASSUMED TO BE DISJOINT AND WITHIN EACH CHR ARE LISTED IN INCREASING SEQUENCE ORDER
# Computes a windowed-average with a given window and step size of all the observations with a given state
# Writes results to $winFile

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 5) { die "Usage: stateDiff.pl inFile winFile tgtState winSize stepSize"; }

# Save the arguments into meaningfully-named variables
my ($inFile, $winFile, $tgtState, $winSize, $stepSize) = @ARGV;
if($winSize<1) { die "ERROR: window size must be >=1!"; }
if($stepSize > $winSize) { die "ERROR: step size must be no larget than the window size!"; }

open(my $in, "<$inFile")  || die "ERROR opening file \"$inFile\"! $!"; 
open(my $out, ">$winFile") || die "ERROR opening file \"$winFile\"! $!";

# Print out the header of the differences file
print $out "chrom\tstart\tstop\tcnt\n";

# Skip the header line
my $line = <$in>;
my $lnum = 2;

my ($chrom, $start, $stop, $state);
my $curChrom = "";

# Load the first line of the file
$line = <$in>; $lnum++; ($chrom, $start, $stop, $state) = processLine($line);

do {
	#if($start1 != 0) { die "Starting point of file \"$inFile1\" is not at 0!"; }
	$curChrom = $chrom;
	print "Chromosome $curChrom\n";
	
	my @win = ();
	my $winSum=0;
	my $cur = $start;
	my $stepsSincePrint = 0;

	# Keep going while we're still on the same chromosome and there is still data in the input tfile
	while($chrom eq $curChrom)
	{
		while($cur < $stop) {
			#print "$curChrom: cur=$cur, stop=$stop, state=$state, [$winSum / ",scalar(@win),"] = ",list2StrSep(\@win,""),"\n";
			# Skip observations from irrelevant states
			#if($state != $tgtState) {
				# Push an empty count into the window and don't increase the sum
				push(@win, 0);
			#} else {
				# Add 1 to the window and its sum to indicate an observation
				#push(@win, 1);
				#$winSum++;
			#}
			
			# If the window is full and we've made the full step
			#print "#win=",scalar(@win)," winSize=$winSize, stepsSincePrint=$stepsSincePrint, stepSize=$stepSize, winSum=$winSum, win=@win\n";
			if(scalar(@win) == $winSize) {
				# Check if a window has completed and if so, print it out
				completeWin(\$stepsSincePrint, $cur, $winSum, $winSize, $stepSize, "    ");
				
				# Remove the oldest difference from the window and its sum
				$winSum -= splice(@win, 0, 1)
			}
			#print "cur=$cur, diff=$diff, state1=$state1, state2=$state2\n";
			
			$cur++;
			$stepsSincePrint++;
		}
		
		# We've finished a line from file1 or file2, so load the next one
		if($cur==$stop) { 
			$line = <$in>; $lnum++; 
			if($line) { ($chrom, $start, $stop, $state) = processLine($line); }
			else      { last; }
			# # If this observation is at the right state, focus on it
			# if($state == $tgtState) { $cur = $start; }
			# # Otherwise, skip it
			# else                    { $cur = $stop; }
		}
	}
	
# Keep looping while there are more chromosomes left in the files
} while($line);

close($in);
close($out);

sub processLine
{
	my ($line, $indent) = @_;
	
	chomp $line;
	my @fields = split(/\s+/, $line);
	if(scalar(@fields) <4) { die "ERROR: wrong number of fields in line \"$line\"!"; }
	
	my ($chrom, $start, $stop, $state) = @fields;
	#print "    state=$state\n";
	return ($chrom, $start, $stop, $state);
}

sub completeWin
{
	my ($stepsSincePrint, $cur, $winSum, $winSize, $stepSize, $indent) = @_;
	
	if($$stepsSincePrint>=$stepSize) { 
		print $out "$curChrom\t",($cur-$winSize+1),"\t",($cur),"\t",($winSum/$winSize),"\n";
		print "$curChrom\t",($cur-$winSize+1),"\t",($cur),"\t",($winSum/$winSize),"\n";
		$$stepsSincePrint=0;
	}
	
}

# Given a list of strings, returns a string that contains all the strings, separated by $separator
sub list2StrSep
{
	my ($list, $separator) = @_;
	
	if(not defined $list) { return ""; }
	if(ref $list ne "ARRAY") { confess("[common] list2StrSep() ERROR: list is not an array!"); }
	
	my $str="";
	for(my $i=0; $i<scalar(@$list); $i++)
	{ 
		$str .= $$list[$i];
		if($i<scalar(@$list)-1)
		{ $str .= $separator; }
	}
	return $str;
}
