#$ -S /usr/bin/perl

use strict;
use warnings;

#my $in_file = '/mnt/coldstorage/open-transfers/client_pickup/121018_SN404_0207_AD17P8ACXX/Project_Blelloch_Lab_RagaKrishnakumar/Sample_RK';
my @ids = ("1_", "2_", "3_", "4_", "5_", "6_", "7_", "8_");
#my @ids = ("1_");
my $out_file = '/mnt/iscsi_speed/blelloch/RK_2012/';
my $abc;

foreach $abc(@ids) {
	for (1..5) {
		my $files = '/mnt/coldstorage/open-transfers/client_pickup/121018_SN404_0207_AD17P8ACXX/Project_Blelloch_Lab_RagaKrishnakumar/Sample_RK' . $abc . $_ . '/';
		print "$files\n";
		system "scp $files/*.gz $out_file";
		system "gunzip $out_file/*.fastq.gz";
		my $out_name = '/mnt/iscsi_speed/blelloch/RK_2012/' . $abc . $_ . '.fastq';
		system "cat $out_file/RK*.* >$out_name";
		system "rm $out_file/RK*.fastq";	
	}
}




# foreach my $lib (keys %libraries) {
# 	my %seqs;
# 
# 	#first, i need to make a directory!
# 	my $directory = $lib . '_r';
# 	mkdir $directory unless (-d $directory);
# 	mkdir "$directory/eland_mapped" unless (-d "$directory/eland_mapped");
# #	my $open_me =  '/home/tmp/081112_30DL9AAXX/Data/C1-36_Firecrest1.9.5_19-11-2008_root/Bustard1.9.5_19-11-2008_root/GERALD_19-11-2008_root/' . $libraries{$lib};
# 	my $open_me = $libraries{$lib};
# 	open my $FH_IN , "<" , $open_me or die "you suck\n";
# 	while (my $line = <$FH_IN> ) {
# 		chomp $line;
# 		my @features = split /\t/, $line;
# 		if (($features[0] =~ m/^([ATGC]+)TCGTAT/) and (length $1 >= 15 and length $1 <= 30)) {
# 			my $sequence = $1;
# 			my $length = length $sequence;
# 			$seqs{$length}{$sequence} += $features[1];
# 		}
# 	}
# 	close $FH_IN;
# 	
# 	#i want to go through the lengths and print them out into a fasta file for eland
# 	foreach my $length_key (keys %seqs) {
# 		my $out_file = $directory . '/' . $lib . '_' . $length_key . '.fa';
# 		open my $FH_OUT , ">>" , $out_file or die;
# 		foreach my $seq_key (keys %{$seqs{$length_key}}) {
# 			print $FH_OUT '>' , '_' , $seq_key , '_' , $seqs{$length_key}{$seq_key} , "\n";
# 			print $FH_OUT $seq_key , "\n";
# 		}
# 		close $FH_OUT;
# 	}
# 
# 	for (27..30 ) {
# 	        my $eland_executable = '/GAPipeline-1.0/Eland/eland_' . $_;
# 		my $query_file = '/home/babiarzj/mollys_analysis/' . $directory . '/' . $lib . '_' . $_ . '.fa';
# 		#eland for the genome	
# 		my $genome_out = '/home/babiarzj/mollys_analysis/' . $directory . '/eland_mapped/' . $lib . '_' . $_ . '.genome.map';
# 		system "$eland_executable $query_file $squashed_genome $genome_out";
# 		#eland for mmy mirnas
# 		my $mirna_out = '/home/babiarzj/mollys_analysis/' . $directory . '/eland_mapped/' . $lib . '_' . $_ . '.mirna.map';
# 		system "$eland_executable $query_file $squashed_mirnas $mirna_out";
# 	}
# 
# }



__END__
