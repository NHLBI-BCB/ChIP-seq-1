#!/usr/bin/perl

use strict;
use warnings;

if(scalar(@ARGV) != 4) { die "Usage: peakAlign.pl genesFile peaksFile matchesFile alignDist"; }

my $genesFile   = $ARGV[0];
my $peaksFile   = $ARGV[1];
my $matchesFile = $ARGV[2];
my $alignDist   = $ARGV[3];

# Load the chromosome data
my %genes = ();

open(my $genesF, "<$genesFile") || die "ERROR opening file \"$genesFile\" for reading! $!";
# Skip the header line
<$genesF>;

for(my $lnum=1; my $line=<$genesF>; $lnum++) {
	chomp $line;
	my @fields = split(/\s/, $line);
	if(scalar(@fields) != 4) { die "ERROR on line $lnum of file \"$genesFile\"! Expected fields (chromNum start stop name) but got ".scalar(@fields)." fields. line=\"$line\"."; }
	my ($chromNum, $start, $stop, $name) = @fields;
	push(@{$genes{$chromNum}}, {start=>$start, stop=>$stop, name=>$name});
	#or for hash version: $genes{$chromNum}{$name} = {start=>$start, stop=>$stop};
	
	#long hash version of above (perl does if statement automatically)
	#my %info = (start=>$start, stop=>$stop);
	#if(not defined $genes{$chromNum}) {
	#	my %infoHash = ($name => \%info);
	#	$genes{$chromNum} = \%infoHash;
	#	#key "$chromNum" of %genes has \%info as a value
	#	#\%info points to the hash %info, which contains the keys start, stop and name
	#	#a hash can have mulitple keys, but each key can only be associated with one value
	#} else {
	#	$genes{$chromNum}{$name} = \%info;
	#}

	#long list version of above (perl does if statement automatically)
	#my %info = (start=>$start, stop=>$stop, name=>$name);
	#if(not defined $genes{$chromNum}) {
	#	my @infoList = (\%info);
	#	$genes{$chromNum} = [\%info];
	#	#key "$chromNum" of %genes has \%info as a value
	#	#\%info points to the hash %info, which contains the keys start, stop and name
	#	#a hash can have mulitple keys, but each key can only be associated with one value
	#} else {
	#	push(@{$genes{$chromNum}}, \%info);
	#}

}
close($genesF);

# Read the peaks file and for each peak find the closest gene
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
	my @matches = findNearestGene(\%genes, $chromNum, $start, $stop, $alignDist); #findNearestGene(genelist,chromnum,start,stop,aligndist)
	foreach my $matchGene (@matches) {
		#print "    matchGene=$matchGene->{start} - $matchGene->{stop}\n";
		#if(!findExactGene(\%allGeneMatches, $chromNum, $matchGene))
		{ push(@{$allGeneMatches{$chromNum}}, {geneStart=>$matchGene->{start}, 
			                                    geneStop=>$matchGene->{stop}, 
			                                    geneName=>$matchGene->{name}, 
			                                    peakStart=>$start,              
			                                    peakStop=>$stop}); }
			                                    #Raga - what if there is a chromNum for which no peak was found (i.e. alignDist didn't match)?  Does it know to just ignore that?
			                                    #skinny arrow is used when you want the nth element of a hash, but you are using a REFERENCE TO A HASH to point to the hash (same with references/pointers to lists)
	}
}
close($peaksF);


# Save all the gene matches into a file
open(my $matchesF, ">$matchesFile") || die "ERROR opening file \"$matchesFile\" for writing! $!";
#print $matchesF "peak chr\tpeak start\tpeak stop\tgene name\tgene chr\tgene start\tgene stop\n";
foreach my $chromNum (keys %allGeneMatches) {
	foreach my $match (@{$allGeneMatches{$chromNum}})
	{ print $matchesF "$chromNum\t$match->{peakStart}\t$match->{peakStop}\t$match->{geneName}\t$chromNum\t$match->{geneStart}\t$match->{geneStop}\n"; }
}
close($matchesF);

### Subroutines called by the main code ###

sub findNearestGene
{
	my ($genesRef, $chromNum, $start, $stop, $alignDist) = @_;
	#above is a COPY of scalars in findNearestGene (scalars) in above script.  The \%genes, which is a POINTER to %genes, becomes the scalar $genesRef because you cannot use an actual hash in the @_ of a sub function
	#print "        findNearestGene(alignDist=$alignDist)\n";
	my @matches = ();
	#the line below does the following: 
	#1)@{$genesRef->{$chromNum}} - pulls out all 'genes' (genes being a hash of things, see %genes) that are on the same chromosome as the "chromNum"th peak
	#2)goes through each of the elements (i.e. genes) pulled out by 1)
	foreach my $gene (@{$genesRef->{$chromNum}}) {
		#skinny arrow means that $genesRef is a POINTER, not the actual thing
		#print "            ($gene->{start} - $start)=",($gene->{start} - $start)," ($gene->{start} - $stop)=",($gene->{start} - $stop),"\n";
		if(abs($gene->{start} - (($start+$stop)/2)) <= $alignDist)
		{ push(@matches, $gene); }
	}
	return @matches;
}

#sub findExactGene
#{
#	my ($genes, $chromNum, $searchGene) = @_;
#	
#	foreach my $gene (@{$genes->{$chromNum}}) {
#		if(($gene->{start} == $searchGene->{start}) && 	
#		   ($gene->{stop}  == $searchGene->{stop})) {
#		   print "        $chromNum - $gene->{start} - $gene->{stop}\n";
#			return $gene;
#		}
#	}
#	# We could not find the gene so return nothing
#	return undef;
#}