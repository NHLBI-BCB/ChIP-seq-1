#!/usr/bin/perl
# Causes Perl to abort if there are any obvious mistakes in the script
use strict;
use warnings;

# Genes file:
# Chrom Gene_start(bp) Gene_stop(bp) Gene_name
#
# Reads file:
# Chrom Read_start(bp) Read_stop(bp)
#
# Output:
# Gene_name Gene_length(kbp) Num_reads
#
# Num_reads: number of reads where [Read_start, Read_stop] entirely encompassed inside [Gene_start, Gene_stop]
#

# If we aren't given two command line arguments, die with an error that explains the correct arguments
if(scalar(@ARGV) != 3) { die "Usage: readGeneCount.pl geneFile readsFile outFile"; }

# Save the arguments into meaningfully-named variables
my ($genesFile, $readsFile, $outFile) = @ARGV;

my %genes = ();
open(my $genesF, "<$genesFile") || die "ERROR opening file \"$genesFile\" for reading! $!";
# Skip the header
<$genesF>;

my $genesLnum=2;
while(my $line=<$genesF>) {
	chomp $line;
	my @fields = split(/\s/, $line);
	if(scalar(@fields) != 4) { die "ERROR: line $genesLnum has ",scalar(@fields)," fields! Expecting 4."; }
	
	my ($chromNum, $gStart, $gStop, $gName) = @fields;
	# Flip the gene's start and end so that start < end
	if($gStop < $gStart)
	{ ($gStop, $gStart) = ($gStart, $gStop); }
		
	# Index this gene's record
	push(@{$genes{$chromNum}}, {gStart=>$gStart, gStop=>$gStop, gName=>$gName, count=>0});
	$genesLnum++;
}
close($genesF);

{
	my $cnt=0;
	foreach my $chromNum (keys %genes)
	{ $cnt += scalar(@{$genes{$chromNum}}); }
	print "#genes=$cnt, genesLnum=$genesLnum\n";
}

open(my $readsF, "<$readsFile") || die "ERROR opening file \"$readsFile\" for reading! $!";
# Skip the header
<$readsF>;

my $readsLnum=2;
while(my $line=<$readsF>) {
	chomp $line;
	my @fields = split(/\s/, $line);
	if(scalar(@fields) != 3) { die "ERROR: line $readsLnum has ",scalar(@fields)," fields! Expecting 3."; }
	
	my ($chromNum, $rStart, $rStop) = @fields;
	# Flip the read's start and end so that start < end
	if($rStop < $rStart)
	{ ($rStop, $rStart) = ($rStart, $rStop); }
	
	# Find the gene that is closest to this read
	foreach my $gene (@{$genes{$chromNum}}) {
		if($gene->{gStart}<=$rStart && $rStop<=$gene->{gStop}) { $gene->{count}++; }
	}	
	$readsLnum++;
}
close($readsF);
my $totalReads = $readsLnum-1;

{
	my $cnt=0;
	foreach my $chromNum (keys %genes)
	{ $cnt += scalar(@{$genes{$chromNum}}); }
	print "#genes=$cnt, genesLnum=$genesLnum\n";
}

open(my $outF, ">$outFile") || die "ERROR opening file \"$outFile\" for writing! $!";
print $outF "Gene_name\tGene_length(kbp)\tNum_reads(per million)\n";
foreach my $chromNum (sort keys %genes) {
	#print "genes{$chromNum}=",obj2Str($genes{$chromNum},"    "),"\n";
	
	foreach my $gene (@{$genes{$chromNum}}) {
		if($gene->{count}>0)
		{ 
			my $geneLenKb = ($gene->{gStop}-$gene->{gStart})/1000;
			print $outF "$gene->{gName}\t$geneLenKb\t",(($gene->{count}*1000000/$totalReads)/$geneLenKb),"\n"; }
	}
}
close($outF);

## Returns the human-readable string representation of the given object
#sub obj2Str
#{
#	my ($obj, $indent) = @_;
#	
#	my $str="";
#	my $firstLine=1;
#	
#	if((ref $obj) eq "ARRAY")
#	{
#		my $allScalar=1;
#		foreach my $v (@$obj) { if((ref $v) ne "") { $allScalar=0; last; } }
#		
#		if($allScalar) { $str .= list2Str($obj); $firstLine=0; }
#		else {
#			my $i=0;
#			foreach my $v (@$obj) {
#				if($firstLine)
#				{ $str .= "\n"; $firstLine=0; }
#				$str .= $indent."$i: ".obj2Str($v, $indent."    ")."\n";
#				$i++;
#			}
#		}
#	}
#	elsif((ref $obj) eq "HASH")
#	{ 
#		my $allScalar=1;
#		foreach my $key (keys %$obj) { if((ref $obj->{$key}) ne "") { $allScalar=0; last; } }
#		
#		if($allScalar) { $str .= hash2Str($obj); $firstLine=0; }
#		else {
#			foreach my $key (sort keys %$obj) {
#				if($firstLine)
#				{ $str .= "\n"; $firstLine=0; }
#				$str .= "${indent}$key => ".obj2Str($obj->{$key}, $indent."    ")."\n";
#			}
#		}
#	}
#	elsif((ref $obj) eq "CODE") {
#		use B qw(svref_2object);
#		my $cv = svref_2object ( $obj );
#		my $gv = $cv->GV;
#		$str .= $gv->NAME."()";
#	}
#	else
#	{ $str = $obj; }
#	
#	return $str;	
#}
#
## Converts a list of pbjects into a list
#sub list2Str
#{
#	my ($list) = @_;
#	
#	my $out = "(";
#	my $i=1;
#	foreach my $val (@$list)
#	{
#		$out .= "$val";
#		if($i < scalar(@$list))
#		{ $out .= ", "; }
#		$i++;
#	}
#	$out.=")";
#	return $out;
#}
#
#sub hash2Str
#{
#	my ($hash) = @_;
#	my $first = 1;
#	my $out = "[";
#	if(defined $hash) { 
#		foreach my $key (sort keys %$hash)
#		{
#			if(!$first) { $out.=", "; }
#			if(exists $$hash{$key})
#			{ $out .= "$key => $$hash{$key}"; }
#			else 
#			{ $out .= "$key => "; }
#			$first = 0;
#		}
#	}
#	$out .= "]";
#	return $out;
#}
