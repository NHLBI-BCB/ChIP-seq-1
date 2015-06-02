#!/usr/bin/perl

use strict;
use warnings;

if(scalar(@ARGV) != 4) { die "Usage: peakAlign.pl chromFile peaksFile matchesFile alignDist"; }

my $chromFile   = $ARGV[0];
my $peaksFile   = $ARGV[1];
my $matchesFile = $ARGV[2];
my $alignDist   = $ARGV[3];

# Load the chromosome data
my %chroms = ();
open(my $chromF, "<$chromFile") || die "ERROR opening file \"$chromFile\" for reading! $!";
# Skip the header line
<$chromF>;

for(my $lnum=1; my $line=<$chromF>; $lnum++) {
	chomp $line;
	my @fields = split(/\s/, $line);
	#Raga - why not: if(scalar(@fields) != 4) { die "ERROR on line $lnum of file \"$chromFile\"! Expected fields (chromNum start stop name) but got ".scalar(@fields)." fields. line=\"$line\"."; }
	if(scalar(@fields) != 4) { die "ERROR on line $lnum of file \"$chromFile\"! Expected fields (chromNum start stop direction) but got ".scalar(@fields)." fields. line=\"$line\"."; }
	my ($chromNum, $start, $stop, $name) = @fields;
	#if($dir eq "+")
	{ push(@{$chroms{$chromNum}}, {start=>$start, stop=>$stop, name=>$name}); }
	#Raga - why are we not also pushing chromNum here?  does it just know to do that?  Comment ref. 
	#else
	#{ push(@{$chroms{$chromNum}}, {start=>$stop,  stop=>$start}); }
}
close($chromF);

# Read the peaks file and for each peak find the closest chromosome Raga - you mean closest gene?
open(my $peaksF, "<$peaksFile") || die "ERROR opening file \"$peaksFile\" for reading! $!";
# Skip the header line
<$peaksF>;

my %allGeneMatches = ();
for(my $lnum=1; my $line=<$peaksF>; $lnum++) {
	chomp $line;
	my @fields = split(/\s/, $line);
	if(scalar(@fields) != 3) { die "ERROR on line $lnum of file \"$peaksFile\"! Expected fields (chromNum start stop direction) but got ".scalar(@fields)." fields. line=\"$line\"."; }
	my ($chromNum, $start, $stop) = @fields;
	#print "chromNum=$chromNum, start=$start, stop=$stop\n";
	my @matches = findNearestGene(\%chroms, $chromNum, $start, $stop, $alignDist);
	foreach my $matchGene (@matches) {
		#print "    matchGene=$matchGene->{start} - $matchGene->{stop}\n";
		#if(!findExactGene(\%allGeneMatches, $chromNum, $matchGene))
		{ push(@{$allGeneMatches{$chromNum}}, {geneStart=>$matchGene->{start}, 
			                                    geneStop=>$matchGene->{stop}, 
			                                    geneName=>$matchGene->{name}, 
			                                    peakStart=>$start,              
			                                    peakStop=>$stop}); }
			                                    #Raga - see Comment ref.
			                                    #Raga - what if there is a chromNum for which no peak was found (i.e. alignDist didn't match)?  Does it know to just ignore that?
			                                    #Raga - what does skinny arrow mean?
	}
}
close($peaksF);

# Save all the gene matches into a file
open(my $matchesF, ">$matchesFile") || die "ERROR opening file \"$matchesFile\" for writing! $!";
#print $matchesF "peak chr\tpeak start\tpeak stop\tgene name\tgene chr\tgene start\tgene stop\n";
foreach my $chromNum (keys %allGeneMatches) {
	foreach my $match(@{$allGeneMatches{$chromNum}})
	{ print $matchesF "$chromNum\t$match->{peakStart}\t$match->{peakStop}\t$match->{geneName}\t$chromNum\t$match->{geneStart}\t$match->{geneStop}\n"; }
}
close($matchesF);

### Subroutines called by the main code ###

sub findNearestGene
{
	my ($genes, $chromNum, $start, $stop, $maxDist) = @_;
	
	#print "        findNearestGene(maxDist=$maxDist)\n";
	my @matches = ();
	foreach my $gene (@{$genes->{$chromNum}}) {
		#print "            ($gene->{start} - $start)=",($gene->{start} - $start)," ($gene->{start} - $stop)=",($gene->{start} - $stop),"\n";
		if((abs($gene->{start} - $start) <= $maxDist) || 
		   (abs($gene->{start} - $stop)  <= $maxDist))
		{ push(@matches, $gene); }
	}
	return @matches;
}

sub findExactGene
{
	my ($genes, $chromNum, $searchGene) = @_;
	
	foreach my $gene (@{$genes->{$chromNum}}) {
		if(($gene->{start} == $searchGene->{start}) && 	
		   ($gene->{stop}  == $searchGene->{stop})) {
		   print "        $chromNum - $gene->{start} - $gene->{stop}\n";
			return $gene;
		}
	}
	# We could not find the gene so return nothing
	return undef;
}