#problem 1
#!/usr/bin/perl

my @numbers=();
my @file=('~/input1.txt', '~/input2.txt');
my @filename=('input1.txt','input2.txt');
my $numLines = 0;

for(my $i=0; $i<scalar(@filename); $i++) {
	open(my $file, "<$filename.txt") || die "ERROR opening file \"$filename\" for reading! $!";
	while(my $line=<$file>) {
		chomp $line;
		push (@numbers, $line); #how do i tell it to go into two different arrays depending on what the original file name is?
		$numLines++; 
	}
	close($file);
}
#can't finish this version without answering that question...

#LONGER ALTERNATIVE

#!/usr/bin/perl
my @numbers=();
my @file=('~/input1.txt');
my @filename=('input1.txt');
my $numLines = 0;

open(my $file, "<$filename.txt") || die "ERROR opening file \"$filename\" for reading! $!";
while(my $line=<$file>) {
	chomp $line;
	push (@numbers, $line); 
	$numLines++; 
}	
close($file);

my @numbers2=();
my @file=('~/input2.txt');
my @filename=('input2.txt');

open(my $file, "<$filename.txt") || die "ERROR opening file \"$filename\" for reading! $!";
while(my $line=<$file>) {
	chomp $line;
	push (@numbers2, $line);
	$numLines++; 
}	
close($file);

open(my $output, ">output") || die "ERROR opening file \"output\" for writing! $!";
foreach my $i (@numbers) {
	my $j=$i+$numbers2[$i];
	print $output "$j\n";
	}	
close($output);
	

