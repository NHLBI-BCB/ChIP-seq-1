#problem 2
#!/usr/bin/perl
#again, not sure how to loop the opening of multiple files onto different arrays. will just do it sequentially

my @text=();
my @file=('~/text.txt');
my @filename=('text.txt');
my $numLines = 0;

open(my $file, "<$filename.txt") || die "ERROR opening file \"$filename\" for reading! $!";
while(my $line=<$file>) {
	chomp $line;
	push (@text, $line);
	$numLines++; 
}	
close($file);

my @lnums=();
my @file=('~/lnums.txt');
my @filename=('lnums.txt');

open(my $file, "<$filename.txt") || die "ERROR opening file \"$filename\" for reading! $!";
while(my $line=<$file>) {
	chomp $line;
	push (@lnums, $line);
	$numLines++; 
}	
close($file);

open(my $output, ">output") || die "ERROR opening file \"output\" for writing! $!";
foreach my $num (@lnums) {
	my $j=$text[$num];
	print $output "$j\n";
	}	
close($output);
	

