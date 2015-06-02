#!/g/g15/bronevet/apps/minions/perl/bin/perl

use strict;
use warnings;
use threads;
use threads::shared;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval);
use POSIX qw(ceil floor);
use List::Util qw[min max];
use Carp qw(carp cluck croak confess longmess);
use Storable qw(nstore store_fd nstore_fd retrieve_fd freeze thaw dclone);
use IPC::Open3;

$common::infinity = 1e100;

$common::success        = 1;
$common::failRetry      = -1;
$common::failRegenerate = -2;
$common::failFinal      = -3;

$|=1;
#my @r = ls($ARGV[0]);
#foreach my $m (@r)
#{
#	print "\"$m\"\n";
#}
1;

sub noop
{}

###########################################
###### DIRECTORY MANAGEMENT ROUTINES ######
###########################################

sub ls
{
	my ($lsPath) = @_;
	
	if($lsPath eq "")
	{ return listDir("."); }
	
	# break the path along the /'s 
	my @pathList = split(/\//, $lsPath);
	my @lsPathChars = split(//, $lsPath);
	
	if($#lsPathChars==-1)
	{ return (); }
	else
	{
		# if this is an absolute path
		if($lsPathChars[0] eq "/")
		{ return ls_rec("/", @pathList); }
		else
		{ return ls_rec("", @pathList); }
	}		
}

sub ls_rec
{
	my ($prefixPath, @pathList) = @_;
	my @results = ();
	
	#print "ls_rec: prefixPath=$prefixPath, ";
	#foreach my $p (@pathList)
	#{ print "$p/"; }
	#print "\n";
	
	if($#pathList==-1) {
		if($prefixPath eq "" || !(-e $prefixPath))
		{ return (); }
		else
		{ return ($prefixPath); }
	}
	
	# the version of $prefixPath to which we'll append sub-paths
	my $appendPrefixPath;
	if($prefixPath eq "")
	{ $appendPrefixPath = ""; }
	elsif($prefixPath eq "/")
	{ $appendPrefixPath = $prefixPath; }
	else
	{ $appendPrefixPath = "$prefixPath/"; }
	
	my $cur = shift(@pathList);
	#print "   cur=$cur\n";
	# if the next entry on the path list contains wildcards
	if($cur =~ /[*]/) {
		#print "   wildcard, prefixPath=$prefixPath\n";
		# list through the directory $prefixPath, looking for matches
		my @contents;
		if($prefixPath eq "")
		{ @contents = listDir("."); }
		else
		{ @contents = listDir($prefixPath); }
		
		# generate a Perl regular expression pattern from the original pattern 
		# (just replace all *'s with .*'s)
		my $pattern = "^$cur\$";
		#print "before pattern = $pattern\n";
		$pattern =~ s/[*]/.*/g;
		#print "after pattern = $pattern, #contents=$#contents\n";
		foreach my $c (@contents) {
			#print "   c=$c, pattern=$pattern\n";
			if($c =~ /$pattern/)
			{
				#print "       success.\n";
				# for each match, look deeper in the match's directory tree
				push(@results, ls_rec("$appendPrefixPath$c", @pathList));
			}
		}
	} else {
		# for each match, deeper in the next path element's directory tree
		push(@results, ls_rec("$appendPrefixPath$cur", @pathList));
	}
	
	#print "results=",list2Str(\@results),"\n";
	return @results;
}


sub ls_regexp
{
	my ($lsPath) = @_;
	
	if($lsPath eq "")
	{ return listDir("."); }
	
	$lsPath =~ s/\/+/\//g; # Filter out duplicate /'s
	
	# break the path along the /'s 
	my @pathList = split(/\//, $lsPath);
	my @lsPathChars = split(//, $lsPath);
	
	if($#lsPathChars==-1)
	{ return (); }
	else
	{
		# if this is an absolute path
		if($lsPathChars[0] eq "/")
		{ splice(@pathList, 0, 1); return ls_rec_regexp("/", @pathList); }
		else
		{ return ls_rec_regexp("", @pathList); }
	}		
}

sub ls_rec_regexp
{
	my ($prefixPath, @pathList) = @_;
	my @results = ();
	
	#print "ls_rec: prefixPath=$prefixPath, ";
	#foreach my $p (@pathList) { print "$p/ "; } print "\n";
	
	if($#pathList==-1) {
		if($prefixPath eq "")
		{ return (); }
		else
		{ return ($prefixPath); }
	}
	
	# The version of $prefixPath to which we'll append sub-paths 
	# (either empty string or terminated by a '/')
	my $appendPrefixPath;
	if($prefixPath eq "")
	{ $appendPrefixPath = ""; }
	elsif($prefixPath eq "/")
	{ $appendPrefixPath = $prefixPath; }
	else
	{ $appendPrefixPath = "$prefixPath/"; }
	
	#print "   cur=$cur\n";
	# List through the directory $prefixPath, looking for matches
	my @contents;
	if($prefixPath eq "")
	{ @contents = listDir("."); }
	else
	{ @contents = listDir($prefixPath); }
	
	my $pattern = shift(@pathList);
	#print "after pattern = $pattern, prefixPath=$prefixPath, #contents=$#contents\n";
	foreach my $c (@contents) {
		if($c =~ /^$pattern$/)
		{
			#print "       success.\n";
			# for each match, look deeper in the match's directory tree
			push(@results, ls_rec_regexp("$appendPrefixPath$c", @pathList));
		}
	}
	
	return @results;
}

# Returns the list of paths of all the files or directories within directory $prefixPath that obey certain conditions 
#    (all returned paths are offset relative to $prefixPath)
# $pattern    - A path is considered matching if $pattern eq "" or if its last element matches the $pattern regexp (no initial ^ or trailing $ needed).
# $patternYes - If =true, ls_Recursive() only returns matching paths. Otherwise, returns non-matching paths.
# $incFiles - If =true, returns matching files
# $termDirs - If =0, returns matching directories. Otherwise, only returns matching directories that do not 
#             contain matches. 
# Returns the list of paths of all the files or directories within directory $prefixPath that obey certain conditions 
#    (all returned paths are offset relative to $prefixPath)
# $pattern    - A path is considered matching if $pattern eq "" or if its last element matches the $pattern regexp (no initial ^ or trailing $ needed).
# $patternYes - If =true, ls_Recursive() only returns matching paths. Otherwise, returns non-matching paths.
# $incFiles - If =true, returns matching files
# $termDirs - If =0, returns matching directories. Otherwise, only returns matching directories that do not 
#             contain matches. 
sub ls_Recursive
{
	my ($prefixPath, $pattern, $patternYes, $incFiles, $termDirs, $indent) = @_;
	#print "ls_Recursive($prefixPath, $pattern, $patternYes, $incFiles, $termDirs, $indent)\n";
	my @results = ();

	if($prefixPath eq "")
	{ $prefixPath = "."; }
	
	my @contents = listDir($prefixPath);
	#print "$prefixPath: #contents=$#contents\n";
	
	foreach my $file (@contents)
	{
		my $fullFilePath = "$prefixPath/$file";
		#print "${indent}ls_Recursive() $fullFilePath, directory=",(-d $fullFilePath),"  ($file =~ /^$pattern\$/) = ",($file =~ /^$pattern$/)," incFiles=$incFiles\n";
		if(-d $fullFilePath)
		{
			
			my @ret = ls_Recursive($fullFilePath, $pattern, $patternYes, $incFiles, $termDirs, $indent."    ");
			#print "${indent}ret=@ret\n";
			# If the directory name matches the $pattern
			if(($patternYes && ($pattern eq "" || $file =~ /^$pattern$/)) ||
				(!$patternYes && ($pattern ne "" && !($file =~ /^$pattern$/))))
			{
				# If we're supposed to return directories that have no sub-directories and this is the case OR
				# We're returning all directories
				if(@ret==() || !$termDirs)
				{ push(@results, $fullFilePath); }
			}
			
			push(@results, @ret);
		}
		else
		{
			# Add this file if it matches the $pattern and we are looking for files
			if($incFiles && 
			   (($patternYes && ($pattern eq "" || $file =~ /^$pattern$/)) ||
				 (!$patternYes && ($pattern ne "" && !($file =~ /^$pattern$/))))
			  )
			{ push(@results, $fullFilePath); }
		}
	}
	
	return @results;
}

#my $debug = 0;
#sub ls_Recursive
#{
#	my ($prefixPath, $pattern, $patternYes, $incFiles, $termDirs, $indent) = @_;
#	
#	my $numThreads:shared;
#	$numThreads = 0;
#	my $maxRecThreads = 100;
#	my $maxRecThreadsObserved = 0;
#	my $maxSpawnDepth=0;
#	my @ret = ls_Recursive_rec($prefixPath, $pattern, $patternYes, $incFiles, $termDirs, $indent, \$numThreads, $maxRecThreads, \$maxRecThreadsObserved, 0, $maxSpawnDepth);
#	print "maxRecThreadsObserved=$maxRecThreadsObserved\n";
#	return @ret;
#}
#
#sub ls_Recursive_rec
#{
#	my ($prefixPath, $pattern, $patternYes, $incFiles, $termDirs, $indent, $numThreads, $maxRecThreads, $maxRecThreadsObserved, $curDepth, $maxSpawnDepth) = @_;
#	
#	if($debug>=2){	print "ls_Recursive_rec() prefixPath=$prefixPath\n"; }
#
#	my @results = ();
#
#	if($prefixPath eq "")
#	{ $prefixPath = "."; }
#	
#	my @contents = listDir($prefixPath);
#	
#	# Figure out the number of files in @contents that are directories and store this info in %isDir
#	my %isDir = ();
#	my $numDirs = 0;
#	foreach my $file (@contents)
#	{
#		my $fullFilePath = "$prefixPath/$file";
#		if(-d $fullFilePath)
#		{
#			$isDir{$fullFilePath} = 1;
#			$numDirs++;
#		}
#	}
#	
#	if($debug>=1){	print "ls_Recursive_rec() prefixPath=$prefixPath, numDirs=$numDirs\n"; }
#	
#	# True if we'll spawn a separate thread for each sub-directory's ls_Recursive_rec call and False if we'll iterate over them in series
#	my $spawnThreads=0;
#	if($numDirs>1 && $curDepth<=$maxSpawnDepth)
#	{ $spawnThreads = ls_Recursive_checkSpawnThreads($prefixPath, $numThreads, $maxRecThreads, $maxRecThreadsObserved, $numDirs); }
#	if($debug>=2){	print "${indent}$prefixPath: spawnThreads=$spawnThreads, numDirs=$numDirs, #contents=$#contents\n"; }
#	
#	# References to the lists returned by recursive calls to ls_Recursive_rec
#	my @subdirRets = ();
#	# References to spawned threads
#	my %spawnedThr = ();
#	foreach my $file (@contents)
#	{
#		my $fullFilePath = "$prefixPath/$file";
#		if($debug>=2){	print "${indent}ls_Recursive() $fullFilePath, directory=",$isDir{$fullFilePath},"  ($file =~ /^$pattern\$/) = ",($file =~ /^$pattern$/)," incFiles=$incFiles\n"; }
#		if($isDir{$fullFilePath})
#		{
#			# Process sub-directories in parallel
#			if($spawnThreads)
#			{
#				if($debug>=1){	print "${indent}$prefixPath: spawning thread for $fullFilePath\n"; }
#				($spawnedThr{$file}) = threads->create(\&ls_Recursive_rec, $fullFilePath, $pattern, $patternYes, $incFiles, $termDirs, $indent."    ", $numThreads, $maxRecThreads, $maxRecThreadsObserved, $curDepth+1, $maxSpawnDepth);
#			}
#			# Process sub-directories in series
#			else
#			{
#				my @ret = ls_Recursive_rec($fullFilePath, $pattern, $patternYes, $incFiles, $termDirs, $indent."    ", $numThreads, $maxRecThreads, $maxRecThreadsObserved, $curDepth+1, $maxSpawnDepth);
#				ls_Recursive_processRecCall($file, $prefixPath, $pattern, $patternYes, $termDirs, $indent, \@ret, \@results);
#				if($debug>=2){	print "${indent}#ret=$#ret, $results=$#results\n"; }
#			}
#		}
#		else
#		{
#			# Add this file if it matches the $pattern and we are looking for files
#			if($incFiles && 
#			   (($patternYes && ($pattern eq "" || $file =~ /^$pattern$/)) ||
#				 (!$patternYes && ($pattern ne "" && !($file =~ /^$pattern$/))))
#			  )
#			{ push(@results, $fullFilePath); }
#		}
#	}
#	
#	my @files = keys %spawnedThr;
#	if($spawnThreads && $#files != $numDirs-1)
#	{ die "!!!!! #files=$#files, numDirs=$numDirs, prefixPath=$prefixPath"; }
#		
#	# If we process sub-directories in parallel
#	if($spawnThreads)
#	{
#		# Wait for each of the recursive threads to complete
#		foreach my $file (keys %spawnedThr)
#		{
#			if($debug>=1){ print "$prefixPath: waiting on $file\n"; }
#			my @ret = $spawnedThr{$file}->join();
#			#my @threads = threads->list();
#			if($debug>=1){ print "${indent}$prefixPath: $file => ",($#ret+1),"\n"; }
#			ls_Recursive_processRecCall($file, $prefixPath, $pattern, $patternYes, $termDirs, $indent, \@ret, \@results);
#		}
#		
#		# We're done, so decrement the number of active threads appropriately
#		ls_Recursive_unspawnThreads($prefixPath, $numThreads, $numDirs);
#	}
#	
#	if($debug>=1){	print "${indent}$prefixPath: Returning #results=$#results\n"; }
#	#print "$prefixPath >>>>\n";
#	return (@results);
#}
#
#sub ls_Recursive_checkSpawnThreads
#{
#	my ($prefixPath, $numThreads, $maxRecThreads, $maxRecThreadsObserved, $numDirs) = @_;
#
#	lock($$numThreads);
#	#print "$prefixPath: numDirs=$numDirs, numThreads=$$numThreads, maxRecThreads=$maxRecThreads \n";
#	# If we haven't yet spawned more threads than the maximum, we'll spawn threads for each sub-directory
#	if($$numThreads+$numDirs < $maxRecThreads)
#	{ 
#		$$numThreads += $numDirs;
#		$$maxRecThreadsObserved = max($$maxRecThreadsObserved, $$numThreads);
#		if($debug>=1){	print "$prefixPath: <<< numThreads=$$numThreads\n"; }
#		return 1;
#	}
#	else
#	{ return 0; }
#}
#
#sub ls_Recursive_unspawnThreads
#{
#	my ($prefixPath, $numThreads, $numDirs) = @_;
#	
#	lock($$numThreads);
#	#my $thread_count = threads->list();
#	#my @threads = threads->list();
#
#	$$numThreads -= $numDirs;
#	if($debug>=1){	print "$prefixPath: numDirs=$numDirs, numThreads=$$numThreads >>>\n"; }
#	#if($$numThreads != $#threads+1) { die "ERROR: numThreads=$$numThreads != #threads=$#threads\n"; }
#}
#
#sub ls_Recursive_processRecCall
#{
#	my ($file, $prefixPath, $pattern, $patternYes, $termDirs, $indent, $ret, $results) = @_;
#	
#	my $fullFilePath = "$prefixPath/$file";
#	
#	# If the directory name matches the $pattern
#	if(($patternYes && ($pattern eq "" || $file =~ /^$pattern$/)) ||
#		(!$patternYes && ($pattern ne "" && !($file =~ /^$pattern$/))))
#	{
#		# If we're supposed to return directories that have no sub-directories and this is the case OR
#		# We're returning all directories
#		if(@$ret==() || !$termDirs)
#		{ push(@$results, $fullFilePath); }
#	}
#	
#	push(@$results, @$ret);
#}

# Returns a list of the given directory's contents, omitting . and ..
# Each element in the returned list is just a name, not the full path.
sub listDir
{
	my ($dirName) = @_;

	opendir(my $dir, $dirName);
	#my @matches = grep(/$cur/,readdir($dir));
	my @contents = readdir($dir);
	closedir($dir);
	
	#print "#contents = $#contents, dirName=$dirName\n";
	
	my @filtered = ();
	# remove . and ..
	foreach my $c (@contents)
	{
		if($c ne "." && $c ne "..")
		{ push (@filtered, $c); }
	}
	
	return @filtered;
}

#################################
###### STRUCTURED FILE I/O ######
#################################

# Given a file that represent a hash: each line contains multiple white-space separated fields.
# Matches the initial fields to the keys and returns the remaing fields of the first matching line
sub hashFileGetVal
{
	my ($fName, @hashKeys) = @_;
	
	open(my $f, "<$fName") || confess("[common] hashFileGetVal() ERROR opening file \"$fName\" for reading!");
	while(my $line = <$f>)
	{
		chomp $line;
		
		#print "line=$line\n";
		# skip blank lines
		if($line ne "")
		{
			#if($line =~ /^\s*(\S+)\s+(\S+)\s*$/)
			my @lineFields = split(/\s+/, $line);
			
			#print "$#hashKeys<=$#lineFields\n";
			if($#hashKeys<=$#lineFields)
			{
				my $allMatch = 1;
				my $i;
				for($i=0; $i<=$#hashKeys; $i++)
				{
					#print "$i: $hashKeys[$i] ne $lineFields[$i]\n";
					if($hashKeys[$i] ne $lineFields[$i])
					{
						$allMatch = 0;
					}
				}
				#print "allMatch=$allMatch\n";
				if($allMatch)
				{
					my @ret = ();
					for(; $i<=$#lineFields; $i++)
					{ push (@ret, $lineFields[$i]); print "$lineFields[$i]\n";}
					close($f);
					return @ret;
				}
			}
			#else { die "[common] hashFileGetVal() ERROR parsing line \"$line\"!"; }
		}
	}
	close($f);
	return ();
}

# Given a file that represent a hash: each line contains some number white-space separated fields,
# with the first being the key and the remaining fields being the values.
# returns the list of values associated with the key
sub hashFileGetVals
{
	my ($fName, $key) = @_;
	
	open(my $f, "<$fName") || confess("[common] hashFileGetVal() ERROR opening file \"$fName\" for reading!");
	while(my $line = <$f>)
	{
		chomp $line;
		
		# skip blank lines
		if($line ne "")
		{
			if($line =~ /^\s*(\S+)((?:\s+\S+)*)\s*$/)
			{
				if($1 eq $key)
				{ 
					my @vals = ();
					my $valStr = $2;
					while($valStr =~ /^\s+(\S+)((?:\s+\S+)*)\s*$/)
					{
						push(@vals, $1);
						$valStr = $2;
					}
					close($f);
					return @vals;
				}
			}
			else { confess("[common] hashFileGetVals() ERROR parsing line \"$line\"!"); }
		}
	}
	close($f);
	
	return ();
}

# Loads the given file and returns a hash representation of its contents.
# Each line of the file is treated as a record, with the first $numKeys whitespace-separated fields
#    being the keys and the remaining fields being the values.
# The hash representation has $numKeys levels, one for each key and the keys are
#    mapped to lists of values.
# It is assumed that no two lines in the file contains the same key combo.
sub hashFileGetHash
{
	my ($fName, $numKeys) = @_;
	
	if($numKeys <= 0) { confess("[common] hashFileGetVal() ERROR numKeys($numKeys) <= 0!"); }
	
	my %fileHash = ();
	
	my $lineNum=1;
	open(my $f, "<$fName") || confess("[common] hashFileGetVal() ERROR opening file \"$fName\" for reading!");
	while(my $line = <$f>)
	{
		chomp $line;
		
		# skip blank lines
		if($line ne "")
		{
			if($line =~ /^\s*(\S+)((?:\s+\S+)*)\s*$/)
			{
				my @vals = ();
				my $valStr = $line;
				while($valStr =~ /^\s*(\S+)((?:\s+\S+)*)\s*$/)
				{
					push(@vals, $1);
					$valStr = $2;
				}
				# Take the first, $numKeys values from vals and make them the keys or complain 
				# if we don't have that many entries
				if(scalar(@vals)<$numKeys)
				{ confess("[common] hashFileGetVals() ERROR: line $lineNum \"$line\" contains too few keys (".scalar(@vals)."!"); }
				else
				{
					my @hKeys = splice(@vals, 0, $numKeys);
					#print "hKeys=(@hKeys) vals=(@vals)\n";
					assignHash(\%fileHash, \@hKeys, \@vals);
				}
				#print "$1 => @vals\n";
			}
			else { confess("[common] hashFileGetVals() ERROR parsing line \"$line\"!"); }
		}
		$lineNum++;
	}
	close($f);
	
	return \%fileHash;
}

# Returns the labeled hash stored in the given tab-separated file. The first $numKey columns correspond to hierarchically-organized
# keys in the hash while the subsequent columns correspond to the values to be stored under their respective keys.
# This format stores column names in the first row of the file, providing the names of both they keys and the values. 
# Each line corresponds to a hash that is stored under a nested key and each data value in the line is also stored
# within in this hash indexed by its column label. It is possible to to provide both scalar and array data values.
# Scalars are the default: if a given column has a non-blank title with no ':' in it, it is a scalar. However, if a column
# title is "title:array" or if a column with a title is followed by one or more columns with blank titles, then these
# columns correspond to array entries. In this case the function stores all the data values in the same array in an actual
# list, keyed under the array column's name (omitting ":array").
sub hashFileGetLabeledHash
{
	my ($fName, $numKeys) = @_;
	
	if($numKeys <= 0) { confess("[common] hashFileGetLabeledHash() ERROR numKeys($numKeys) <= 0!"); }
	
	my %fileHash = ();
	my $index2name = {};
	my $scalarType=0;
	my $arrayType =1;	
	my $index2type = {};
	
	my $lineNum=1;
	open(my $f, "<$fName") || confess("[common] hashFileGetLabeledHash() ERROR opening file \"$fName\" for reading!");
	while(my $line = <$f>)
	{
		chomp $line;
		
		# skip blank lines
		if($line ne "")
		{
			# Pull out all the field names in the line, including any blank names that correspond to array entries
			$line .= "\tdummy";
			my @vals = split(/[\t]/, $line);
			splice(@vals, $#vals, 1);
			
			# Take the first, $numKeys values from vals and make them the keys or complain 
			# if we don't have that many entries
			if(scalar(@vals)<$numKeys)
			{ confess("[common] hashFileGetLabeledHash() ERROR: line $lineNum \"$line\" contains too few keys (".scalar(@vals)."!"); }
			
			my @hKeys = splice(@vals, 0, $numKeys);

			# If this is the line that provides the names of the columns, fill the index2name hash with the mapping of column 
			# indexes to their respective names
			if($lineNum==1) {
				# Extract from the title line the mapping of field names to their indexes within their rows
				my $i=0;
				my $lastFieldName = "";
				foreach my $fieldName (@vals) {
					if($fieldName ne "") { 
						$index2name->{$i} = $fieldName;
						# If this field is specifically labeled as an array in its field name, give it that type.
						# Otherwise, fields are scalar by default unless we actually see multiple values for the field.
						if($fieldName =~ /^[^:]+:([^:]+)$/ && $2 eq "array")
						{ $index2type->{$i} = $arrayType; }
						else
						{ $index2type->{$i} = $scalarType; }
						$lastFieldName = $fieldName;
					}
					# If the current field name is blank, it corresponds to an array index of a prior field name
					else { 
						$index2name->{$i}   = $lastFieldName;
						$index2type->{$i}   = $arrayType;
						$index2type->{$i-1} = $arrayType;
					}
					$i++;
				}
				#print "index2name=",hash2Str($index2name),"\n";
				#print "index2type=",hash2Str($index2type),"\n";
			}
			else
			{
				#print "hKeys=(@hKeys) vals=#",scalar(@vals),"=(@vals)\n";

				my $i=0;
				foreach my $val (@vals) {
					# Add the mapping fieldName -> $val  to %fileHash{hKeys}
					if($index2type->{$i} == $scalarType)
					{ assignHash(\%fileHash, [@hKeys, $index2name->{$i}], $val); }
					else
					{ 
						my $curL = getHash(\%fileHash, [@hKeys, $index2name->{$i}]);
						push(@$curL, $val);
						assignHash(\%fileHash, [@hKeys, $index2name->{$i}], $curL);
					}
					$i++;
				}
			}
			#print "$1 => @vals\n";
		}
		$lineNum++;
	}
	close($f);
	
	return \%fileHash;
}

# Returns a list that contains each line (chomped) from the given file.
# If the file does not exist, returns the empty list.
sub file2list
{
	scalar(@_)==1 || confess("[common] list2file() ERROR: wrong number of arguments: ".scalar(@_)."!");
	my ($fName) = @_;
	
	if(!(-e $fName)) { return (); }
	
	open(my $file, "<$fName") || confess("[common] file2List() ERROR opening file \"$fName\" for reading!");
	
	my @list = ();
	while(my $line=<$file>)
	{
		chomp $line;
		push(@list, $line);
		#print "#list=$#list\n";
	}
	
	close($file);
	
	return @list;
}

# Writes out the contents of the given list into a file, with each list element separated by $sep 
# or "\n" if $sep is not provided
sub list2file
{
	scalar(@_)>=2 || confess("[common] list2file() ERROR: list and/or file not specified: ".scalar(@_)." arguments!");
	scalar(@_)<=3 || confess("[common] list2file() ERROR: too many arguments: ".scalar(@_)."!");
	my ($list, $fName, $sep);
	if(scalar(@_) == 2)
	{
		($list, $fName) = @_;
		$sep = "\n";
	}
	else
	{ ($list, $fName, $sep) = @_; }

	open(my $file, ">$fName");
	foreach my $elt (@$list)
	{ print $file "$elt$sep"; }
	close($file);	
}



##################################
###### SYSTEM CALL ROUTINES ######
##################################

# Executes the given system call for upto $timeout seconds and then kills it. 
# Returns (true, retVal) if the system call completed in time and (false) on a timeout, with retVal
#    being the return value of the command
# If the call completed in time, $? is NOT set appropriately. // and the call's return value is not available.
sub timedSystem
{
	my ($timeout, $cmd) = @_;
	
	my $childPID = fork();
	if($childPID != 0)
	{
		my $sysCallSignal : shared;
		my $sysCallActive : shared;
		my $cmdReturn     : shared;
		$sysCallActive = 0;
		
		lock($sysCallSignal);
		$sysCallActive = 1;
		
		my ($ss, $sms) = gettimeofday;
				
		my $thr = threads->new(\&waitOnSysCall, \$sysCallSignal, \$sysCallActive, \$cmdReturn, $childPID);
		# check for the system call's completion, polling once a second
		while($sysCallActive)
		{
			while(!cond_timedwait($sysCallSignal, time() + 1))
			{
				my $elapsed = tv_interval([$ss, $sms]);
				if($elapsed > $timeout)
				{
					print "Timed out.\n"; 
					# Get the children of the shell that spawned the command 
					# (there should only be one child, which is the process executing the command)
					my @childPIDs = getchildPIDs($childPID);
					foreach my $childPID (@childPIDs)
					{ 
						#my @grandchildPIDs = getchildPIDs($childPID);
						#foreach my $pid (@grandchildPIDs)
						#{
							print "kill $childPID\n"; 
							system "kill $childPID"; 
						#}
					}
					print "kill $childPID\n"; 
					system "kill $childPID"; 
					$thr->join();
					#print "timedSystem() Done 1\n";
					return (0);
				} #$thr->kill('KILL'); }
				#print "Still not signalled time=",time(),"\n";
				threads->yield();
			}
			#print "Signalled!\n";
		}
		$thr->join();
		# we now release the $sysCallSignal lock
		return (1, $cmdReturn);
	}
	else
	{
		# The child executes the command. This process will become the shell and will fork off another
		# process that will actually perform the command. The worker process will either finish on its 
		# own or be killed by the parent.
		exec($cmd);
	}
	#print "timedSystem() Done 2\n";
}

# Waits on the given pid and informs the main thread when the given process is finished
sub waitOnSysCall
{
	my ($signalRef, $activeRef, $cmdReturnRef, $pid) = @_;
	
	#print "chld pid = $pid\n";
	waitpid($pid,0);
	print "waitOnSysCall() Done Waiting. Return status = $?\n";
	$$cmdReturnRef = $?;
	
	##print "ls -l $dir\n";
	#system "$cmd";
	$$activeRef=0;
	cond_signal($$signalRef);
}

sub getchildPIDs
{
	my ($pid) = @_;
	
	my @childPIDs = ();

#print "getchildPIDs($pid)\n";
#	system "ps -f";
	my $out = `ps -f`;
	my @lines = split(/\n/,$out);
	my $i=0;
	my %titles = ();
	foreach my $line (@lines)
	{
		my @data = split(/\s+/,$line);
		if($i==0)
		{
			my $j=0;
			foreach my $fieldName (@data)
			{ 
				$titles{$fieldName} = $j;
				#print "titles{$fieldName} = $titles{$fieldName}\n";
				$j++;
			}
		}
		else
		{
#			print "data[$titles{\"PPID\"}] = $data[$titles{\"PPID\"}]\n";
			if($data[$titles{"PPID"}] eq $pid)
			{ #print "pushing\n"; 
				push(@childPIDs, $data[$titles{"PID"}]); }
		}
		$i++;
	}
	return @childPIDs;
}

sub testSystem
{
	my ($cmd, $dieOnError, $silent, $verbose) = @_;
	if(not defined $dieOnError) { $dieOnError = 1; }
	if(not defined $silent) { $silent = 0; }
	
	my $pid = open3( my $to_child, # Autovivified when false. 
	              my $fr_child_stdout, # Autovivified when false. 
	              my $fr_child_stderr,        # Same as $fr_child when false. 
	              "$cmd"); 
	
	my $res = "";
	while(my $line=<$fr_child_stdout>) {
		$res .= $line;
		 if($verbose) { print $line; }
	}
	if($fr_child_stderr) {
		while(my $line=<$fr_child_stderr>) {
			$res .= $line;
			 if($verbose) { print $line; }
		}
	}
	waitpid($pid, 0);

	#my $res = `$cmd`;
	return (testSystemSucc("", "", $dieOnError, $silent), $res);
}

# Checks whether the most recent system call completed successfully and if not, releases the given lock
# and emits the appropriate error message. 
# $dieOnError - if true, errors cause this routine to call die. Otherwise, the routine returns 
#               true if the command succeeded and false if it failed.
# $silent - prints no error message if true, and yells if false
sub testSystemSucc
{
	my ($moduleName, $lockFName, $dieOnError, $silent) = @_;
	#print "testSystemSucc() $?\n";
	
	my ($succ, $mesg) = testSystemSuccMesg($moduleName, $lockFName, $dieOnError, $silent);
	return $succ;
}
sub testSystemSuccMesg
{
	my ($moduleName, $lockFName, $dieOnError, $silent) = @_;
	#print "testSystemSucc() $?\n";
	
	if ($? == -1)
	{
		if($lockFName ne "")
		{ system "$ENV{CUTILS_ROOT}/bin/unlockFile $lockFName";  }
		my $mesg;
		if(!$silent) { print "$mesg\n"; }
		if($dieOnError)
		{ confess("$moduleName ERROR: !!!!! FAILED TO EXECUTE: $!"); }
		return (0, "$moduleName ERROR: !!!!! FAILED TO EXECUTE: $!");
	}
	elsif ($? & 127)
	{
		if($lockFName ne "")
		{ system "$ENV{CUTILS_ROOT}/bin/unlockFile $lockFName"; }
		my $out = sprintf "$moduleName ERROR: !!!! DIED WITH SIGNAL %d, %s COREDUMP\n". ($? & 127). (($? & 128) ? 'with' : 'without');
		if(!$silent) { print "$out\n"; }
		if(!$silent) { print "($? & 127) = ",($? & 127),", ($? & 127)==0 = ",(($? & 127)==0),"\n"; }
		#if(($? & 127)==0)
		#{ print "Returning Failure.\n"; return 0; }
		if($dieOnError)
		{ confess($out); }
		return (0, $out);
	}
	elsif($? != 0)
	{
		if($lockFName ne "")
		{ system "$ENV{CUTILS_ROOT}/bin/unlockFile $lockFName"; }
		my $out = sprintf "$moduleName ERROR: !!!! EXITED WITH VALUE ".($? >> 8).". Message=\"$!\".\n";
		if(!$silent) { print "$out\n"; }
		#print "${indent}dieOnError=$dieOnError\n";
		if($dieOnError)
		{ confess($out); }
		return (0, $out);
	}
	
	return (1, "success");
}

# Calls timedSystem and tests whether it completed successfully.
# Returns (noTimeout, ret):
#    noTimeout - true if the command returned successfully and false if it timed out
#    ret - the command's return value
sub testTimedSystem
{
	my ($cmd, $timeout, $dieOnError, $silent) = @_;
	if(not defined $dieOnError) { $dieOnError = 1; }
	if(not defined $silent) { $silent = 0; }
	
	my ($noTimeout, $ret) = timedSystem($timeout, $cmd);
	return (testTimedSystemSucc("", "", $noTimeout, $ret, $dieOnError, $silent), $noTimeout, $ret);
}

# Checks whether the most recent timed system call completed successfully and if not, releases the given lock
# and dies with the appropriate error message
# Returns true on success and false on timeout
sub testTimedSystemSucc
{
	my ($moduleName, $lockFName, $noTimeout, $cmdReturn, $dieOnError, $silent) = @_;
	
	if(!$noTimeout)
	{
		if(!$silent) { print "$moduleName WARNING: Command timed out!\n"; }
#		system "$ENV{CUTILS_ROOT}/bin/unlockFile $outPathOrig/.lock"; 
		return 0;
	}
	elsif($cmdReturn!=0)
	{
		my $out = "$moduleName ERROR: Command aborted!\n"; 
#		system "$ENV{CUTILS_ROOT}/bin/unlockFile $outPathOrig/.lock"; 
		if(!$silent) { print "$out\n"; }
		if($dieOnError) { confess($out); }
	}
	return 1;
}

#
## List of locks current held by idempotent functions
#my @heldLocks;
#
## Calls the given function while doing locking to ensure that the function is called atomically
#sub lockedFunc
#{
#	my ($func, $args, $workDir, $label, $jobID, $indent) = @_;
#	#print "${indent}lockedIdempotentFunc($func, $args, $workDir, $label, $jobID)\n";
#	
#	#print  "mkdir -p $workDir/control\n";
#	system "mkdir -p $workDir/control";
#	my $lockFile = "$workDir/control/lock.${label}";
#	
#	#print "${indent}-e $doneFile=",(-e $doneFile),"\n";
#	my @ret;
#	print "${indent}$ENV{BLAS_VULN_ROOT}/common/schedLockFile.pl $lockFile $jobID\n";
#	system "$ENV{BLAS_VULN_ROOT}/common/schedLockFile.pl $lockFile $jobID";
#	
#	# Record that the given lock is held 
#	push(@heldLocks, $lockFile);
#
#	@ret = $func->(@$args, $indent); 
#	
#	# Record that the given lock is released
#	pop(@heldLocks);
#	
#	system "$ENV{CUTILS_ROOT}/bin/unlockFile $lockFile";
#	
#	return @ret;
#}
#
## Calls the given function with the given arguments while ensuring that any output produced by the function
## is guaranteed to be produced only once. This is done by passing to the function an extra $noOutput argument 
## (follows the regular arguments), which is true if the function must not write any output file. The function
## also gets an appropriate $indent argument, which follows $noOutput. The function's return value is returned
## to the caller.
#sub lockedIdempotentFunc
#{
#	my ($func, $args, $workDir, $label, $jobID, $indent) = @_;
#	#print "${indent}lockedIdempotentFunc($func, $args, $workDir, $label, $jobID)\n";
#	
#	#print  "mkdir -p $workDir/control\n";
#	system "mkdir -p $workDir/control";
#	my $lockFile = "$workDir/control/lock.${label}";
#	my $doneFile = "$workDir/control/done.${label}";
#	
#	print "${indent}-e $doneFile=",(-e $doneFile),"\n";
#	my $ret;
#	if(-e $doneFile)
#	{
#		$ret = $func->(@$args, 1, $indent);
#	}
#	else
#	{ 
#		#print "${indent}$ENV{BLAS_VULN_ROOT}/common/schedLockFile.pl $lockFile $jobID\n";
#		system "$ENV{BLAS_VULN_ROOT}/common/schedLockFile.pl $lockFile $jobID";
#		#print "----";
#		
#		# Record that the given lock is held 
#		push(@heldLocks, $lockFile);
#
#		$ret = $func->(@$args, 0, $indent); 
#		system "echo '$jobID' > $doneFile"; 
#		
#		# Record that the given lock is released
#		pop(@heldLocks);
#		
#		system "$ENV{CUTILS_ROOT}/bin/unlockFile $lockFile";
#	}
#	
#	return $ret;
#}
#
## Resets the done marker of the given idempotent function, meaning that it will be re-executed if it is called again
#sub resetIdempotentFunc
#{
#	my ($workDir, $label, $indent) = @_;
#	
#	my $lockFile = "$workDir/control/lock.${label}";
#	my $doneFile = "$workDir/control/done.${label}";
#	unlink($doneFile); 
#}
#
## Returns true if the idempotent function based in the given directory and using the given label has indeed been executed
#sub isIdempotentFuncDone
#{
#	my ($workDir, $label, $indent) = @_;
#	
#	my $doneFile = "$workDir/control/done.${label}";
#	return (-e $doneFile && (-s $doneFile > 0));
#}
#
## Releases all the locks acquired by calls to lockedIdempotentFunc
#sub releaseHeldLocks
#{
#	foreach my $lockFile (@heldLocks) { system "$ENV{CUTILS_ROOT}/bin/unlockFile $lockFile";  }	
#}
#
# Checks whether the most recent system call completed successfully and if not, releases the given lock
# and emits the appropriate error message. 
# This variant of testSystemSucc releases all locks held by idempotent functions if the call results 
#     in an application abort but otherwise releases no locks
# $dieOnError - if true, errors cause this routine to call die. Otherwise, the routine returns 
#               true if the command succeeded and false if it failed.
# $silent - prints no error message if true, and yells if false
sub testSystemSucc_Idemp
{
	my ($moduleName, $dieOnError, $silent) = @_;
	my $error=0;
	my $mesg="";
	
	if ($? == -1)
	{
		$mesg="$moduleName ERROR: !!!!! FAILED TO EXECUTE: $!";
		$error = 1;
	}
	elsif ($? & 127)
	{
		$mesg = sprintf "$moduleName ERROR: !!!! DIED WITH SIGNAL ".($? & 127).", ".(($? & 128) ? 'with' : 'without')." COREDUMP. ($? & 127) = ".($? & 127).", ($? & 127)==0 = ".(($? & 127)==0);
		$error = 1;
	}
	elsif($? != 0)
	{
		$mesg = sprintf "$moduleName ERROR: !!!! EXITED WITH VALUE ",($? >> 8),". Str=$!\n";
		$error = 1;
	}
	
	if($error)
	{
		if(!$silent) { print "$mesg\n"; }
		if($dieOnError)
		{ 
			# Release All Locks
			#releaseHeldLocks();
			confess($mesg);
		}
		return (0, $mesg);
	}
	else
	{ return (1, $mesg); }
}

# Register the Quit/Abort handler to clean up on program termination or 
# the receipt of any signals in @$signals
sub regAbortHandler
{
	my ($abortHandler, $signals) = @_;
	$SIG{QUIT}  = $abortHandler;
	$SIG{ABRT}  = $abortHandler;
	#$SIG{BREAK} = $abortHandler;
	$SIG{TERM}  = $abortHandler;
	$SIG{INT}   = $abortHandler;
	$SIG{HUP}   = $abortHandler;
	# If we're provided with a signals array, register abortHandler to catch these signals as well
	if(defined $signals && (ref $signals eq "ARRAY")) {
		foreach my $sig (@$signals) {
			$SIG{$sig} = $abortHandler;
		}
	}
}

#############################
###### STRING ROUTINES ######
#############################

# Trim functions from http://www.somacon.com/p114.php
# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
# Left trim function to remove leading whitespace
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}


###########################
###### LIST ROUTINES ######
###########################

# Adapted from http://www.csc.liv.ac.uk/~martin/teaching/comp519/PERL/randperm.html
#    This program will generate a random permutation of the integers
#  { 0, ..., n-1 } for a user specified integer n.  We assume that
#  user inputs a positive integer (if it's negative then we'll get
#  an error as the program executes).  
#
#    We use the Markov chain Monte Carlo method for generating the
#  random permuation.  
#
sub genRandPerm
{
	my ($n) = @_;
	
	srand;  #  seed the random number generator
	
	my @nums = 0 .. $n-1;  #  initialize with the identity permutation 
	
	if($n>1)
	{
		#print "genRandPerm() before nums=";
		#foreach my $p (@nums)
		#{ print "\"$p\" "; }
		#print "\n";
		
		my $iters = 12 * $n**3 * log($n) + 1;
		for(my $i = 1; $i <= $iters; $i++)
		{
			#print "${indent}genRandPerm() i=$i, iters=$iters\n";
			#  Flip a coin, and if heads swap
			# a random adjacent pair of elements.  
			if (rand(1) <= .5) 
			{
				my $k = int( rand($n-1) );
				( $nums [$k], $nums [$k + 1] ) = ($nums [$k + 1], $nums [$k] );
			}
		}
		
		#print "genRandPerm() after nums=",list2Str(\@nums),"\n";
	}
	
	return @nums;
}

# Adapted from http://docstore.mik.ua/orelly/perl/cookbook/ch04_18.htm

# fisher_yates_shuffle( \@array ) : generate a random permutation
# of @array in place
sub genRandPerm2 {
	my ($n) = @_;
	my @nums = 0 .. $n-1; 
	for(my $i=$#nums; $i>0; $i--)
	{
		my $j = int(rand($i+1));
		next if $i == $j;
		($nums[$i], $nums[$j]) = ($nums[$j], $nums[$i]);
	}
	return @nums;
}


# Randomly permutes the given list (passed by reference)
sub permuteList
{
	my ($list) = @_;
	
	if(ref $list ne "ARRAY") { confess("[common] permuteList() ERROR: list is not an array!"); }
	
	my @perm = genRandPerm2(scalar(@$list));
	
	#print "permuteList() #list = $#{@$list} perm =";
	#foreach my $p (@perm)
	#{ print "$p "; }
	#print "\n";
	
	for(my $i=0; $i<=$#perm; $i++)
	{ ($$list[$i], $$list[$perm[$i]]) = ($$list[$perm[$i]], $$list[$i]); }
	
	return $list;
}

# Eliminates the duplicates in the given list (passed by reference)
sub elimDup
{
	my ($list, $indent) = @_;
	
	if(ref $list ne "ARRAY") { confess("[common] elimDup() ERROR: list is not an array!"); }
	
	my %itemIndex = ();
	while(@$list != ())
	{ $itemIndex{pop(@$list)}++; }
	
	foreach my $item (keys %itemIndex)
	{ push(@$list, $item); }
	
	return $list;
}

# Chops up the given list into $numChunks equal pieces and returns
# a list of pointers to these pieces (the original list is untouched).
# Dies if the number of elements in the list is not divisible by $numChunks.
sub chopList
{
	my ($list, $numChunks) = @_;

	if(ref $list ne "ARRAY") { confess("[common] chopList() ERROR: list is not an array!"); }

	if(($#{$list}+1) % $numChunks != 0)
	{ confess("[common.pl] chopList() ERROR: given list has size ".($#{$list}+1).", which is not divisible by numChunks=$numChunks!"); }
	
	my @chunks = ();
	my $j=0;
	for(my $chunk=0; $chunk<$numChunks; $chunk++)
	{
		my @cur = ();
		for(my $i=0; $i<(($#{$list}+1) / $numChunks); $i++, $j++)
		{ push(@cur, $$list[$j]); }
		push(@chunks, \@cur);
		#print "chopList: #cur = $#cur, #chunks=$#chunks\n";
		#my $curOutHistListRef = $chunks[$chunk];
		#my @curOutHistList = @{$chunks[$chunk]};
		#print "chopList: #chunks[$chunk] = $#curOutHistList, curOutHistListRef=$curOutHistListRef\n";
	}
	#for(my $i=0; $i<=$#chunks; $i++)
	#{ 
	#	my @curOutHistList = @$chunks[$i];
	#	print "#chunks[$i] = $#curOutHistList, chunks[$i]=$chunks[$i]\n";
	#	foreach my $n (@$chunks[$i])
	#	{
	#		print "    n=$n\n";
	#	}
	#}
	
	return @chunks;
}


# Returns true if the given value is in the given list (passed by reference) using the $equal function if set or the == operator otherwise.
# Returns false if it is not found.
sub isInList
{
	my ($val, $list, $equal) = @_;
	
	if(ref $list ne "ARRAY") { confess("[common] isInList() ERROR: list is not an array!"); }
	if(defined $equal && (ref $equal ne "CODE")) { confess("[common] isInList() ERROR: equal is not an function!"); }
	
	#print ":isInList: #list = $#{@$list}\n";
	foreach my $listval (@$list)
	{
		if(($equal && $equal->($val, $listval)) ||
		   (!$equal && $val == $listval))
		{ return 1; }
	}
	return 0;
}

# Returns true if the given value is in the given list (passed by reference) using the eq operator, false otherwise
sub isInListEq
{
	my ($val, $list) = @_;
	
	if(ref $list ne "ARRAY") { confess("[common] isInListEq() ERROR: list is not an array!"); }
	
	#print ":isInList: #list = $#{@$list}\n";
	foreach my $listval (@$list)
	{
		#print ":isInList:val=$val, listval=$listval eq=",($val eq $listval),"\n";
		if($val eq $listval)
		{ return 1; }
	}
	return 0;
}

# If the given value is in the given list (passed by reference) using the == operator, returns the index 
# where the value is found (if it appears multiple times, the first appearace). Returns -1 otherwise.
sub findInList
{
	my ($val, $list) = @_;
	
	if(ref $a ne "ARRAY") { confess("[common] findInList() ERROR: a is not an array!"); }
	
	#print ":isInList: #list = $#{@$list}\n";
	my $i=0;
	foreach my $listval (@$list)
	{
		#print ":isInList:val=$val, listval=$listval\n";
		if($val == $listval)
		{ return $i; }
		$i++;
	}
	return -1;
}

# Binary search
# Search array of integers a for given integer $x
# Return index where found or -1 if not found
# Taken from http://staff.washington.edu/jon/dsa-perl/bsearch-copy
sub findInSortedList 
{
	my ($x, $a) = @_;         # search for x in array a
	
	if(ref $a ne "ARRAY") { confess("[common] findInSortedList() ERROR: a is not an array!"); }

	my ($l, $u) = (0, scalar(@$a)-1);   # lower, upper end of search interval
	my $i;                    # index of probe
	while ($l <= $u)
	{
		$i = int(($l + $u)/2);
		if ($$a[$i] < $x)
		{ $l = $i+1; }
		elsif ($$a[$i] > $x)
		{ $u = $i-1; } 
		else # found
		{ return $i; }
	}
	return -1;         # not found
}


# Insert $x into sorted list @$a at its sorted position, allowing duplicates.
# Returns $x's new position in @$a.
# Extended from  http://staff.washington.edu/jon/dsa-perl/bsearch-copy
sub insertInSortedList
{
	my ($x, $a) = @_;         # search for x in array a
	
	if(ref $a ne "ARRAY") { confess("[common] insertInSortedList() ERROR: a is not an array!"); }
	
	return insertInSortedListGen($x, $a, sub{my ($a, $b)=@_; return $a <=> $b; });
}

# Insert $x into sorted list @$a at its sorted position, allowing duplicates.
# Accepts a function that will be used to compare the list entries
# Returns $x's new position in @$a.
# Extended from  http://staff.washington.edu/jon/dsa-perl/bsearch-copy
sub insertInSortedListGen
{
	my ($x, $a, $cmp) = @_;         # search for x in array a

	if(ref $a ne "ARRAY") { confess("[common] insertInSortedListGen() ERROR: a is not an array!"); }
	if(ref $cmp ne "CODE") { confess("[common] insertInSortedListGen() ERROR: cmp is not an function!"); }

	# If the list is empty, insert $x as its only element
	if(scalar(@$a)==0) { 
		push(@$a, $x);
		return 0;
	}
	
	my ($l, $u) = (0, scalar(@$a));  # lower, upper end of search interval
	my $i;                           # index of probe
	while ($l < $u)
	{
		$i = int(($l + $u)/2);
		
		#print "[$l < $i < $u] a[$i]=$$a[$i], x=$x\n";
		if ($cmp->($$a[$i], $x)<0)
		{ $l = $i+1; }
		elsif ($cmp->($$a[$i], $x)>0)
		{ $u = $i; } 
		else # found
		{
			# Insert $x immediately before the current location
			splice(@$a, $i, 0, $x);
			return $i;
		}
	}
	#print "[$l < $i < $u] a[$l]=$$a[$l], x=$x\n";
	if($l<scalar(@$a)) {
		if($cmp->($x, $$a[$l])<0)
		{
			# Insert $x immediately before the current location
			splice(@$a, $l, 0, $x);
			return $l;
		}
		elsif($cmp->($x, $$a[$l])>0)
		{
			# Insert $x immediately after the current location
			splice(@$a, $l+1, 0, $x);
			return $l+1;
		}
		else
		{ confess("[common] insertInSortedList() ERROR: x($x) == a[$i] ($$a[$i]) after loop end!"); }
	# If the new entry belongs at the end of the list
	} else {
		push(@$a, $x);
		return scalar(@$a);
	}
	return -1;         # not found
}


# If the given value is in the given list (passed by reference) using the == operator or the equality function if provided, 
# removes  it and returns True. Returns False otherwise.
sub rmFromListEqFunc
{
	scalar(@_) == 3 || die;
	my ($val, $list, $eqFunc) = @_;
	
	if(not defined $list) { return 0; }
	if(ref $list ne "ARRAY") { confess("[common] rmFromListEqFunc() ERROR: list is not an array!"); }
	if(ref $eqFunc ne "CODE") { confess("[common] addUniqueToList() ERROR: eqFunc is not an function!"); }
	
	my $i=0;
	foreach my $listval (@$list)
	{
		if((defined $eqFunc && $eqFunc->($val, $listval)) ||
		   $val == $listval)
		{
			splice(@$list, $i, 1);
			return 1;
		}
		$i++;
	}
	return 0;
}

# If the given value is in the given list (passed by reference) using the == operator, removes 
# it and returns True. Returns False otherwise.
sub rmFromList
{
	scalar(@_) == 2 || confess("");
	my ($val, $list) = @_;
	
	if(not defined $list) { return 0; }
	if(ref $list ne "ARRAY") { confess("[common] rmFromList() ERROR: list is not an array!"); }
	
	my $i=0;
	foreach my $listval (@$list)
	{
		if($val == $listval)
		{ 
			splice(@$list, $i, 1);
			return 1;
		}
		$i++;
	}
	return 0;
}


# If the given value is in the given list (passed by reference) using the eq operator, returns the index 
# where the value is found (if it appears multiple times, the first appearace). Returns -1 otherwise.
sub findInListEq
{
	my ($val, $list) = @_;
	
	if(not defined $list) { return -1; }
	if(ref $list ne "ARRAY") { confess("[common] findInListEq() ERROR: list is not an array!"); }
	
	#print ":isInList: #list = $#{@$list}\n";
	my $i=0;
	foreach my $listval (@$list)
	{
		#print ":isInList:val=$val, listval=$listval\n";
		if($val eq $listval)
		{ return $i; }
		$i++;
	}
	return -1;
}

# If the given value is in the given list (passed by reference) using the eq operator, removes 
# the first instance of the value and returns True. Returns False otherwise.
sub rmFromListEq
{
	my ($val, $list) = @_;
	
	if(not defined $list) { return 0; }
	if(ref $list ne "ARRAY") { confess("[common] rmFromListEq() ERROR: list is not an array!"); }
	
	my $i=0;
	foreach my $listval (@$list)
	{
		if($val eq $listval)
		{ 
			splice(@$list, $i, 1);
			return 1;
		}
		$i++;
	}
	return 0;
}

# Returns 1 if the given lists contain the same elements (using the == operator) and 0 otherwise
sub listsEqual
{
	my ($list1, $list2) = @_;
	
	if(not defined $list1 && not defined $list2) { return 1; }
	if(ref $list1 ne "ARRAY") { confess("[common] listsEqual() ERROR: list1 is not an array!"); }
	if(ref $list2 ne "ARRAY") { confess("[common] listsEqual() ERROR: list2 is not an array!"); }
	
	if(scalar(@$list1) != scalar(@$list2)) { return 0; }
	
	for(my $i=0; $i<scalar(@$list1); $i++)
	{
		if($$list1[$i] != $$list2[$i])
		{ return 0; }
	}
	return 1;
}

# Returns 1 if the given lists contain the same elements (using the eq operator) and 0 otherwise
sub listsEq
{
	my ($list1, $list2) = @_;
	
	if(not defined $list1 && not defined $list2) { return 1; }
	if(ref $list1 ne "ARRAY") { confess("[common] listsEq() ERROR: list1 is not an array!"); }
	if(ref $list2 ne "ARRAY") { confess("[common] listsEq() ERROR: list2 is not an array!"); }
	
	if(scalar(@$list1) != scalar(@$list2)) { return 0; }
	
	for(my $i=0; $i<scalar(@$list1); $i++)
	{
		if($$list1[$i] ne $$list2[$i])
		{ return 0; }
	}
	return 1;
}

# Returns 1 if the given lists contain the same elements (using the == operator), applying listsEqualDeep and 
#     hashesEqualDeep to any list or hash elements, respectively.
# Returns 0 if they are not equal
sub listsEqualDeep
{
	my ($list1, $list2, $indent) = @_;
	
	if(not defined $list1 && not defined $list2) { return 1; }
	if(ref $list1 ne "ARRAY") { confess("[common] listsEqualDeep() ERROR: list1 is not an array!"); }
	if(ref $list2 ne "ARRAY") { confess("[common] listsEqualDeep() ERROR: list2 is not an array!"); }
	
	if(scalar(@$list1) != scalar(@$list2)) { return 0; }
	
	for(my $i=0; $i<scalar(@$list1); $i++)
	{
		if($$list1[$i] != $$list2[$i])
		{ 
			# Check if these are both lists
			#print "${indent}listsEqualDeep $i: list1[$i]=$$list1[$i], list2[$i]=$$list2[$i]\n";
			if(("$$list1[$i]" =~ "ARRAY") && ("$$list2[$i]" =~ "ARRAY"))
			{ 
				# If they are, recursively call listsEqualDeep on them
				if(!listsEqualDeep($$list1[$i], $$list2[$i], $indent."    "))
				{ return 0; }
			}
			# Check if these are both hashes
			#print "${indent}listsEqualDeep $i: list1[$i]=$$list1[$i], list2[$i]=$$list2[$i]\n";
			elsif(("$$list1[$i]" =~ "HASH") && ("$$list2[$i]" =~ "HASH"))
			{ 
				# If they are, recursively call listsEqualDeep on them
				if(!hashesEqualDeep($$list1[$i], $$list2[$i], $indent."    "))
				{ return 0; }
			}
			# Otherwise, they're not equal so we're done
			else
			{ return 0; }
		}
	}
	return 1;
}

# Adds the given value to the list only of its not already in the list, uses == to compare the values or the given $equal function
# Returns the new $list
sub addUniqueToList
{
	my ($val, $list, $equal) = @_;

	if(not defined $list) { $list = []; }
	if(ref $list ne "ARRAY") { confess("[common] addUniqueToList() ERROR: list is not an array!"); }
	if(ref $equal ne "CODE") { confess("[common] addUniqueToList() ERROR: equal is not an function!"); }

	# Insert $val into $list if it is not already there
	if(!isInList($val, $list, $equal))
	{ push(@$list, $val); }
	
	return $list;
}

# Adds the given value to the list only of its not already in the list, uses eq to compare the values
# Returns the new $list
sub addUniqueToListEq
{
	my ($val, $list) = @_;

	if(not defined $list) { $list = []; }
	if(ref $list ne "ARRAY") { confess("[common] addUniqueToListEq() ERROR: list is not an array!"); }

	# Insert $val into $list if it is not already there
	if(!isInListEq($val, $list))
	{ push(@$list, $val); }
	
	return $list;
}

# Adds the contents of the fromList to the toList only of its not already in the toList, uses == to compare the values or the given $equal function.
# Returns the new $toList
sub addUniqueListToList
{
	my ($fromList, $toList, $equal) = @_;
	
	if(not defined $toList) { $toList = []; }
	if(not defined $fromList) { return $toList; }
	if(ref $fromList ne "ARRAY") { confess("[common] addUniqueListToList() ERROR: list is not an array!"); }
	if(ref $toList ne "ARRAY") { confess("[common] addUniqueListToList() ERROR: list is not an array!"); }

	foreach my $val (@$fromList)
	{
		# Insert $val into $list if it is not already there
		if(!isInList($val, $toList, $equal))
		{ push(@$toList, $val); }
	}
	
	return $toList;
}

# Converts a list of pbjects into a list
sub list2Str
{
	my ($list) = @_;
	
	if(not defined $list) { return "()"; }
	if(ref $list ne "ARRAY") { confess("[common] list2Str() ERROR: list is not an array!"); }
	
	my $out = "(";
	my $i=1;
	foreach my $val (@$list)
	{
		if(defined $val) { $out .= "$val"; }
		
		if($i < scalar(@$list))
		{ $out .= ", "; }
		$i++;
	}
	$out.=")";
	return $out;
}

# Converts a list of hash references into a string
sub hashList2Str
{
	my ($list) = @_;
	
	if(not defined $list) { return "()"; }
	if(ref $list ne "ARRAY") { confess("[common] hashList2Str() ERROR: list is not an array!"); }
	
	my $out = "(";
	my $i=1;
	foreach my $val (@$list)
	{
		$out .= hash2Str($val);
		if($i < (scalar(@$list)-1))
		{ $out .= ", "; }
		$i++;
	}
	$out.=")";
	return $out;
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

# Given a list of objects, returns a string that contains all the strings, separated by $separator
# Each object is converted into a string using the given function $obj2Str
sub listObj2StrSep
{
	my ($list, $obj2Str, $separator) = @_;
	
	if(not defined $list) { return ""; }
	if(ref $list ne "ARRAY") { confess("[common] listObj2StrSep() ERROR: list is not an array!"); }
	
	my $str="";
	for(my $i=0; $i<scalar(@$list); $i++)
	{ 
		$str .= $obj2Str->($$list[$i]);
		if($i<scalar(@$list))
		{ $str .= $separator; }
	}
	return $str;
}

# Returns the human-readable string representation of the given object
sub obj2Str
{
	my ($obj, $indent) = @_;
	
	if(not defined $obj) { return ""; }
	if(not defined $indent) { $indent=""; }
	
	my $str="";
	my $firstLine=1;
	
	if((ref $obj) eq "ARRAY")
	{
		my $allScalar=1;
		foreach my $v (@$obj) { if((ref $v) ne "") { $allScalar=0; last; } }
		
		if($allScalar) { $str .= list2Str($obj); $firstLine=0; }
		else {
			my $i=0;
			foreach my $v (@$obj) {
				if($firstLine)
				{ $str .= "\n"; $firstLine=0; }
				$str .= $indent."$i: ".obj2Str($v, $indent."    ")."\n";
				$i++;
			}
		}
	}
	elsif((ref $obj) eq "HASH")
	{ 
		my $allScalar=1;
		foreach my $key (keys %$obj) { if((ref $obj->{$key}) ne "") { $allScalar=0; last; } }
		
		if($allScalar) { $str .= hash2Str($obj); $firstLine=0; }
		else {
			# Determine whether all the keys are numeric
			my $allNums = 1;
			foreach my $key (keys %$obj) { if(!looks_like_a_number($key)) { $allNums=0; last; } }
			
			my @sortedKeys = ($allNums ? sort {$a <=> $b} keys %$obj: sort {$a cmp $b} keys %$obj);
			foreach my $key (@sortedKeys) {
				if($firstLine)
				{ $str .= "\n"; $firstLine=0; }
				$str .= "${indent}$key => ".obj2Str($obj->{$key}, $indent."    ")."\n";
			}
		}
	}
	elsif((ref $obj) eq "CODE") {
		use B qw(svref_2object);
		my $cv = svref_2object ( $obj );
		my $gv = $cv->GV;
		$str .= $gv->NAME."()";
	}
	else
	{ $str = $obj; }
	
	return $str;	
}

# Returns whether the given string looks like a number.
sub looks_like_a_number
{
	my ($str) = @_;
	if(not defined $str) { return 0; }
	return ($str =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
}

#sub normalizeMtx
#{
#	my ($rows, $cols, $mtx) = @_;
#	
#	
#}

# Given a file, returns the list of chomped lines in the file
#sub file2List
#{
#	my ($fName) = @_;
#	
#	open(my $file, "<$fName") || die "[common] file2List() ERROR opening file \"$fName\" for reading!";
#	my @list = ();
#	while(my $line = <$file>)
#	{
#		chomp $line;
#		push(@list, $line);
#	}
#	close($file);
#	
#	return @list;
#}

###########################
###### HASH ROUTINES ######
###########################

# Returns 1 if the given lists contain the same key/value pairs (using the == operator), applying listsEqualDeep and 
#     hashesEqualDeep to any list or hash elements, respectively.
# Returns 0 if they are not equal
sub hashesEqualDeep
{
	my ($hash1, $hash2, $indent) = @_;
	
	if(ref $hash1 ne "HASH") { confess("[common] hashesEqualDeep() ERROR: hash1 is not a hash!"); }
	if(ref $hash2 ne "HASH") { confess("[common] hashesEqualDeep() ERROR: hash2 is not a hash!"); }
	
	my @keys1 = keys %$hash1;
	my @keys2 = keys %$hash2;
	
	if($#keys1 != $#keys2) { return 0; }
	if(!listsEqualDeep(\@keys1, \@keys2)) { return 0; }
	
	foreach my $key (@keys1)
	{
		if($$hash1{$key} != $$hash2{$key})
		{ 
			# Check if these are both lists
			#print "${indent}hashsEqualDeep $i: hash1{$key}=$$hash1{$key}, hash2{$key}=$$hash2{$key}\n";
			if(("$$hash1{$key}" =~ "ARRAY") && ("$$hash2{$key}" =~ "ARRAY"))
			{ 
				# If they are, recursively call listsEqualDeep on them
				if(!listsEqualDeep($$hash1{$key}, $$hash2{$key}, $indent."    "))
				{ return 0; }
			}
			# Check if these are both hashes
			#print "${indent}hashsEqualDeep $i: hash1{$key}=$$hash1{$key}, hash2{$key}=$$hash2{$key}\n";
			elsif(("$$hash1{$key}" =~ "HASH") && ("$$hash2{$key}" =~ "HASH"))
			{ 
				# If they are, recursively call listsEqualDeep on them
				if(!hashesEqualDeep($$hash1{$key}, $$hash2{$key}, $indent."    "))
				{ return 0; }
			}
			# Otherwise, they're not equal so we're done
			else
			{ return 0; }
		}
	}
	return 1;
}

sub hash2Str
{
	my ($hash) = @_;
	
	if(ref $hash ne "HASH") { confess("[common] hash2Str() ERROR: hash is not a hash!"); }
	
	my $first = 1;
	my $out = "[";
	if(defined $hash) { 
		foreach my $key (sort keys %$hash)
		{
			if(!$first) { $out.=", "; }
			if(exists $$hash{$key})
			{ $out .= "$key => $$hash{$key}"; }
			else 
			{ $out .= "$key => "; }
			$first = 0;
		}
	}
	$out .= "]";
	return $out;
}

sub str2Hash
{
	my ($s, $returnOnError) = @_;

	if(!($s =~ /^\[(.*)\]$/)) {
		if($returnOnError) { return {}; }
		else { confess("[common] str2Hash() ERROR: hash string is not surrounded by []'s!"); }
	}
	
	my @fields = split(/,/, $1);
	my %h=();
	foreach my $f (@fields)
	{
		if(!($f =~ /^([^=>]+)\s*=>\s*(\S*)$/)) {
			if($returnOnError) { return {}; }
			else { confess("[common] str2Hash() ERROR: field string \"$f\" doesn't contain key/value pair!"); }
		}
		$h{trim($1)} = trim($2);
	}
	return \%h;
}

# Given a hash reference, a list of keys and a value, modifies the hash
# to map the list of keys (via multiple levels of hashing) to the value
sub assignHash
{
	my ($hash, $hKeys, $hVal, $keyIndex) = @_;
	
	
	if(defined $hash && ref $hash ne "HASH") { confess("[common] assignHash() ERROR: hash=",(defined $hash? $hash: "")," is not a hash!"); }
	if(ref $hKeys ne "ARRAY") { confess("[common] assignHash() ERROR: hKeys=",(defined $hKeys? $hKeys: "")," is not an array!"); }

	if(not defined $keyIndex) { $keyIndex=0; }

	if(scalar(@$hKeys)==0)
	{ $hash = $hVal; }	
	elsif($keyIndex == scalar(@$hKeys)-1)
	{ $$hash{$$hKeys[$keyIndex]} = $hVal; }
	else
	{ $$hash{$$hKeys[$keyIndex]} = assignHash($$hash{$$hKeys[$keyIndex]}, $hKeys, $hVal, $keyIndex+1); }
	
	return $hash;
}

# Given a hash reference and a list of keys, returns the value currently mapped in the hash under this key hierarchy
sub getHash
{
	my ($hash, $hKeys, $keyIndex) = @_;
	
	if(not defined $hash) { return undef; }
	if(ref $hash ne "HASH") { confess("[common] getHash() ERROR: hash=",(defined $hash? $hash: "")," is not a hash!"); }
	if(ref $hKeys ne "ARRAY") { confess("[common] getHash() ERROR: hKeys=",(defined $hKeys? $hKeys: "")," is not an array!"); }
	
	if(not defined $keyIndex) { $keyIndex=0; }
	
	if(scalar(@$hKeys)==0)
	{ return $hash; }	
	elsif($keyIndex == scalar(@$hKeys)-1)
	{ return $$hash{$$hKeys[$keyIndex]}; }
	else
	{ return getHash($$hash{$$hKeys[$keyIndex]}, $hKeys, $keyIndex+1); }
}

# Given a reference to a multi-level hash, converts the whole thing into a string
sub hash2StrDeep
{
	my ($hash, $indent) = @_;
	
	if(ref $hash ne "HASH") { confess("[common] hash2StrDeep() ERROR: hash=",(defined $hash? $hash: "")," is not a hash!"); }
	
	my $first = 1;
	my $out = "[";
	foreach my $key (sort keys %$hash)
	{
		if(!$first) { $out.=", "; }
		if(exists $$hash{$key}) { 
			$out .= "$key => ";
			if(ref($$hash{$key}) eq "HASH")
			{ $out .= hash2StrDeep($$hash{$key}, $indent."    "); }
			else
			{ $out .= $$hash{$key}; }
		}
		else 
		{ $out .= "$key => "; }
		$first = 0;
	}
	$out .= "]";
	
	#my $out = "[";
	#foreach my $key (sort keys %$hash)
	#{
	#	#if($out ne "") { $out.= "\n"; }
	#	
	#	$out .= "${indent}$key => ";
	#	if(ref($$hash{$key}) eq "HASH")
	#	{ $out .= hash2StrDeep($$hash{$key}, $indent."    "); }
	#	elsif(ref($$hash{$key}) eq "ARRAY")
	#	{ $out .= list2Str($$hash{$key}, $indent."    "); }
	#	else
	#	{ $out .= "$$hash{$key}"; }
	#}
	#$out .= "]";
	return $out;
}

#sub str2HashDeep
#{
#	my ($s, $returnOnError) = @_;
#
#	if(!($s =~ /^\[(.*)\]$/)) {
#		if($returnOnError) { return {}; }
#		else { confess("[common] str2Hash() ERROR: hash string is not surrounded by []'s!"); }
#	}
#	
#	my @fields = split(/,/, $1);
#	my %h=();
#	foreach my $f (@fields)
#	{
#		print "${indent}f=$f\n";
#		if(!($f =~ /^([^=>]+)=>([^=>]+)$/)) {
#			if($returnOnError) { return {}; }
#			else { confess("[common] str2Hash() ERROR: field string \"$f\" doesn't contain key/value pair!"); }
#		}
#		my $key = trim($1);
#		my $val = trim($2);
#		print "${indent}    $key => $val\n";
#		# If the value is also a hash
#		if($val =~ /^\[.+\]$/) { print "${indent}        subhash\n"; $val = str2HashDeep($val, $returnOnError); }
#		$h{$key} = $val;
#	}
#	print "${indent}h=",obj2Str(\%h, $indent."    "),"\n";
#	return \%h;
#}

# Given a reference to a multi-level hash, converts the whole thing into a string.
# Converts the mapped values to a string using the given $val2StrFn function.
sub hash2StrGenDeep
{
	my ($hash, $val2StrFn, $indent) = @_;
	
	if(ref $hash ne "HASH") { confess("[common] hash2StrGenDeep() ERROR: hash=",(defined $hash? $hash: "")," is not a hash!"); }
	if(ref $val2StrFn ne "CODE") { confess("[common] hash2StrGenDeep() ERROR: val2StrFn=",(defined $val2StrFn? $val2StrFn: "")," is not an function!"); }
	
	my $out = "";
	my $i=0;
	my @hashKeys = sort keys %$hash;
	foreach my $key (@hashKeys)
	{
		$out .= "${indent}$key => ";
		if(ref($$hash{$key}) eq "HASH")
		{ $out .= "\n".hash2StrGenDeep($$hash{$key}, $val2StrFn, $indent."    "); }
		else
		{ $out .= &$val2StrFn($$hash{$key}); }
		if($i<scalar(@hashKeys)-1)
		{ $out.="\n"; }
		$i++;
	}
	#$out .= "${indent}]";
	return $out;
}

# Given a reference to a multi-level hash, calls the given function on all hash elements
# $depth levels inside the hash. If $depth is not defined, iterates as deep as possible until 
# the internal type of the hash values is no longer a hash. 
# During each call to $func, it is passed the arguments ($keys, $val, $indent), where:
#    $keys - list of hash keys above the given level
#    $val - the value indexed by $keys
sub iterHash
{
	my ($hash, $depth, $func, $indent) = @_;
	
	if(ref $hash ne "HASH") { confess("[common] iterHash() ERROR: hash=",(defined $hash? $hash: "")," is not a hash!"); }
	if(ref $func ne "CODE") { confess("[common] iterHash() ERROR: func=",(defined $func? $func: "")," is not an function!"); }
	
	return iterHash_ex($hash, $depth, $func, $depth, [], $indent);
}

sub iterHash_ex
{
	my ($hash, $depth, $func, $curDepth, $parentKeys, $indent) = @_;
	
	if(ref $hash ne "HASH") { confess("[common] iterHash_ex() ERROR: hash=",(defined $hash? $hash: "")," is not a hash!"); }
	if(ref $func ne "CODE") { confess("[common] iterHash_ex() ERROR: func=",(defined $func? $func: "")," is not an function!"); }
	
	#print "${indent}iterHash_ex($hash, $depth, $func, $curDepth, $parentKeys)\n";
	# If we need to iterate deeper
	if((defined $depth && $curDepth>0) || ((not defined $depth) && (ref($hash) eq "HASH"))) {
		my $i=0;
		my @hashKeys = sort keys %$hash;
		foreach my $key (@hashKeys)
		{ iterHash_ex($hash->{$key}, $depth, $func, $curDepth-1, [@$parentKeys, $key], $indent);	}
		$i++;
	} else {
		$func->($parentKeys, $hash, $indent);
	}
}

# Returns true if $$hash{$fields[0]}{$fields[1]}{$fields[2]}... is defined, checking one level of the hierarchy at
# a time to keep new portions of the hash to be created unnecessarily just because of this test
sub isDefinedH
{
	my ($hash, @fields) = @_;
	
	if(ref $hash ne "HASH") { confess("[common] isDefinedH() ERROR: hash=",(defined $hash? $hash: "")," is not a hash!"); }
	
	#print "            isDefinedH(hash=",hash2Str($hash),", depth=$depth, fields=",list2Str(\@fields),"\n";
	if(scalar(@fields)>0)
	{
		if(defined $$hash{$fields[0]})
		{ 
			my $first = $fields[0];
			splice(@fields, 0, 1);
			return isDefinedH($$hash{$first}, @fields);
		}
		else
		{ return 0; }
	}
	else
	{ return 1; }
}

# Given a hash, converts it to a list of [$key, $value] pairs from the hash and returns the list
sub hash2List
{
	my ($h, $indent) = @_;
	
	if(ref $h ne "HASH") { confess("[common] isDefinedH() ERROR: h=",(defined $h? $h: "")," is not a hash!"); }
	
	my @l;
	foreach my $k (keys %$h) {
		push(@l, [$k, $$h{$k}]);
	}
	return \@l;
}

# Given a list of hashes, returns a hash that contains the union of the hashes.
# If the hashes in the list share keys, returns failure.
# Returns:
#    (unionHash, status)
sub disjUnionHash
{
	my ($hashes, $indent) = @_;
	
	if(ref $hashes ne "ARRAY") { confess("[common] disjUnionHash() ERROR: hashes is not an array!"); }
	
	my $u = {};
	foreach my $h (@$hashes) {
		if(ref $h ne "HASH") { confess("[common] disjUnionHash() ERROR: list element is not a hash!"); }
		
		foreach my $k (keys %$h) {
			# If we discover a duplicate key, return an error
			if(defined $u->{$k}) { return ({}, $common::failFinal); }
			
			$u->{$k} = $h->{$k};
		}
	}
	
	return ($u, $common::success);
}

##############################
###### NUMERIC ROUTINES ######
##############################

# Returns 1 if the given value is positive, -1 if negative and 0 if 0
sub sign
{
	my ($val) = @_;
	
	if($val > 0) { return 1; }
	elsif($val < 0) { return -1; }
	else { return 0; }
}

# From http://perl.plover.com/IAQ/IAQlist.html
sub odd {
   my $number = shift;
   return !even ($number);
}


# From http://perl.plover.com/IAQ/IAQlist.html
sub even {
   my $number = abs shift;
   return 1 if $number == 0;
   return odd ($number - 1);
}

# Binomial coefficient function
sub binCoeff
{
	my ($n_, $k) = @_;
	
	if($n_==$k){ return 1; }
	elsif($n_>$k)
	{
		# (n * n-1 * n-2 ... 1) / (k * k-1 * ... * 1) = 
		# (n * n-1 * n-2 ... n-k+1)
		my $product = 1;
		for(my $i=$n_; $i>$k; $i--)
		{ $product *= $i; }
		return $product;
	}
	else
	{ confess("[common] binCoeff() ERROR: numerator ($n_) < denominator ($k)!"); }
}


# returns the average of the vector in the given file
sub getVecFileAvg
{
	my ($vecFName) = @_;
	my ($rows, $cols, @vector) = mm_read_ARG_array_colmaj($vecFName);
	#print "$vecFName => rows=$rows, cols=$cols\n";
	my $sum=0.0;
	if($rows == 1)
	{
		for(my $c=0; $c<$cols; $c++)
		{ $sum += $vector[$c][0]; }
		return $sum/$cols;
	}
	elsif($cols == 1)
	{
		for(my $r=0; $r<$rows; $r++)
		{ $sum += $vector[0][$r]; } #print "sum=$sum, vector[1][$r]=$vector[1][$r]\n"; }
		#print "returning $sum/$rows = ",($sum/$rows),"\n";
		return $sum/$rows;
	}
	
	confess("[common] getVecFileAvg() ERROR: Vector file \"$vecFName\" has dimensions ($rows x $cols). Must be a vector!");
}

# negative values get turned into 0's
sub normNeg
{
	my ($val) = @_;
	if($val < 0) { return 0-$val; }
	return $val;
}

# Normalizes each row of the given matrix (stored in column-major order) so that the sum of all 
# the values in each row adds up to 1. All negative matrix entries are turned into 0's. // All matrix entries MUST be non-negative.
# returns 0 on success, non-0 on failure
sub normalizeMtxByRows
{
	my ($rows, $cols, $mtx) = @_;
	
	# We compute the row sums and update the matrix while performing
	# a linear pass in memory, thus improving our cache performance.
	
	# true if the matrix contains negative values and false otherwise
	#my $negValues=0;
	
	my @rowSum;
	for(my $r=0; $r<$rows; $r++)
	{ $rowSum[$r] = 0; }
	
	# compute the row sums
	for(my $c=0; $c<$cols; $c++)
	{
#print "normalizeMtxByRows row sums c=$c\n";
		for(my $r=0; $r<$rows; $r++)
		{
			#print "mtx[$c][$r] = $$mtx[$c][$r]\n";
			$$mtx[$c][$r] = normNeg($$mtx[$c][$r]);
			$rowSum[$r] += $$mtx[$c][$r];
			#negValues = $$mtx[$c][$r]<0 | $negValues;
		}
	}
	
	# We do not allow matrixes to contain negative values
	#if(@negValues) return -1;

	# normalize the rows
	for(my $c=0; $c<$cols; $c++)
	{
#print "normalizeMtxByRows normalize rows c=$c\n";
		for(my $r=0; $r<$rows; $r++)
		{ 
			#print "mtx[$c][$r] = $$mtx[$c][$r] => ";
			$$mtx[$c][$r] /= $rowSum[$r]; 
			#print "$$mtx[$c][$r], rowSum[$r]=$rowSum[$r]\n";
			}
	}
	
	return 0;
}

# Normalizes each column of the given matrix (stored in column-major order) so that the sum of all 
# the values in each column adds up to 1. All negative matrix entries are turned into 0's. // All matrix entries MUST be non-negative.
# returns 0 on success, non-0 on failure
sub normalizeMtxByCols
{
	my ($rows, $cols, $mtx) = @_;
	# We compute the row sums and update the matrix while performing
	# a linear pass in memory, thus improving our cache performance.
	
	# true if the matrix contains negative values and false otherwise
	#my $negValues=0;
	
	for(my $c=0; $c<$cols; $c++)
	{
		# compute the column sum
		my $colSum=0.0;
		for(my $r=0; $r<$rows; $r++)
		{
			$$mtx[$c][$r] = normNeg($$mtx[$c][$r]);
			$colSum += $$mtx[$c][$r];
			#print "mtx[$c][$r] = $$mtx[$c][$r]\n";
			#negValues = $$mtx[$c][$r]<0 | $negValues;
		}
		
		# We do not allow matrixes to contain negative values
		#if($negValues) return -1;
		
		#print "normalizeMtxByCols: col $c, sum = $colSum\n";
		
		# normalize the column
		for(my $r=0; $r<$rows; $r++)
		{ $$mtx[$c][$r] /= $colSum; }
	}
	
	return 0;
}

sub normalizeVec
{
	my ($v) = @_;
	
	# compute the column sum
	my $sum=0.0;
	for(my $r=0; $r<scalar(@$v); $r++)
	{
		$$v[$r] = normNeg($$v[$r]);
		$sum += $$v[$r];
		#negValues = $$mtx[$c][$r]<0 | $negValues;
	}
	
	# We do not allow matrixes to contain negative values
	#if($negValues) return -1;
	
	#print "normalizeVec: sum = $sum\n";
	
	# normalize the vector
	for(my $r=0; $r<scalar(@$v); $r++)
	{ $$v[$r] /= $sum; }
	
	return 0;
}

# Normalizes the vector, operating in chunks of $chunkSize vector elements.
# The vector must be evenly divisible into chunks of size $chunkSize.
#sub normalizeVecChunks
#{
#	my ($v, $chunkSize) = @_;
#	
#	if(scalar(@$v)%$chunkSize != 0) { confess("[common] normalizeVecChunks() ERROR: vector size is not divisible by the chunk size $chunkSize!"); }
#	
#	my $r=0;
#	for(my $c=0; $c<(scalar(@$v)/$chunkSize); $c++)
#	{
#		my $sum=0.0;
#		my $r2=$r;
#		for(my $i=0; $i<$chunkSize; $i++, $r++)
#		{
#			$$v[$r] = normNeg($$v[$r]);
#			$sum += $$v[$r];
#			#negValues = $$mtx[$c][$r]<0 | $negValues;
#		}
#	
#		# We do not allow matrixes to contain negative values
#		#if($negValues) return -1;
#	
#		# Normalize the current chunk to make sure it sums up to 1
#		for(my $i=0; $i<$chunkSize; $i++, $r2++)
#		{ $$v[$r2] /= $sum; }
#	}
#	
#	return 0;
#}

## Computes the sum or average of the given matrix's rows. Returns a list of sums/averages, 
## one entry per matrix column. If $avg==0, computes sums. If $avg==1, computes averages.
#sub sumMtxRows
#{
#	my ($rows, $cols, $mtx, $avg) = @_;
#	
#	# We compute the row sums and update the matrix while performing
#	# a linear pass in memory, thus improving our cache performance.
#	
#	# true if the matrix contains negative values and false otherwise
#	#my $negValues=0;
#	
#	my @rowSum;
#	for(my $r=0; $r<rows; $r++)
#	{ $rowSum[$r] = 0; }
#	
#	# compute the row sums
#	for(my $c=0; $c<$cols; $c++)
#	{
#		for(my $r=0; $r<$rows; $r++)
#		{
#			$$mtx[$c][$r] = normNeg($$mtx[$c][$r]);
#			$rowSum[$r] += $$mtx[$c][$r];
#			#negValues = $$mtx[$c][$r]<0 | $negValues;
#		}
#	}
#	
#	# We do not allow matrixes to contain negative values
#	#if(@negValues) return -1;
#
#	# normalize the rows
#	for(my $c=0; $c<$cols; $c++)
#	{
#		for(my $r=0; $r<$rows; $r++)
#		{ $$mtx[$c][$r] /= $rowSum[$r]; 
#			#print "rowSum[$r]=$rowSum[$r]\n";
#			}
#	}
#	
#	return 0;
#}


# Returns the p-norm the given vector. 
sub vecNorm
{
	my ($v, $p) = @_;

	my $norm = 0;
	
	# iterate through the rows
	foreach my $elt (@$v)
	{
		#print "elt = $elt\n";
		if($p==0)
		{ $norm = max($norm, $elt); }
		else
		{ $norm += $elt ** $p; }
	}
	#print "norm = $norm, ";
	if($p>0)
	{ $norm = $norm ** (1.0/$p); }
	#print "$norm\n";
		
	return $norm;
}

# Returns the sum the given vector. 
sub vecSum
{
	my ($v) = @_;

	my $sum = 0;
	
	# iterate through the rows
	foreach my $elt (@$v)
	{ $sum += $elt; }
	return $sum;
}

# Computes the p-norm of each matrix column. Returns a list of norms,
# one entry per matrix column. The matrix is column major and passed by reference.
sub mtxColsNorm
{
	my ($mtx, $p) = @_;
	my @norms = ();
	
	#print "    mtx=$#{@$mtx}\n";
	# iterate through the columns
	foreach my $col (@$mtx)
	{
		#print "    col=$col\n";
		my $norm = 0;
		
		# iterate through the rows
		foreach my $rowElt (@$col)
		{
			#print "rowElt = $rowElt\n";
			if($p==0)
			{ $norm = max($norm, $rowElt); }
			else
			{ $norm += $rowElt ** $p; }
		}
		
		
		#if($p==3){ my $power = 1.0/4; print "$norm, $norm ** ",(1.0/$p),"=",($norm ** (1.0/$p)),", $norm ** $power=",($norm ** $power),", "; }
		if($p>0)
		{ $norm = $norm ** (1.0/$p); }
		#print "norm=$norm\n";
		
		push(@norms, $norm);
	}
	return @norms;
}

# Computes the p-average of the given matrix's rows. Returns a list of averages, 
# one entry per matrix column. A p-average of numbers (x_1, ..., x_n) is
# (Sum_i (x_i^p)) / n^p
sub mtxRowAvg
{
	my ($rows, $mtx, $p) = @_;
	
	my @colNorms = mtxColsNorm($mtx, $p);
	#print "#colNorms=$#colNorms\n";
	# divide each column norm by the number of rows to get the final average
	for(my $i=0; $i<=$#colNorms; $i++)
	{
		$colNorms[$i] /= $rows;
	}
	return @colNorms;
}

# Returns the p-norm of the difference between the two vectors (lists passed in by reference)
# Returns -1 on error, such as if the two lists have different lengths.
sub vecNormDiff
{
	my ($p, $l1, $l2) = @_;
	
	if(scalar(@$l1) != scalar(@$l2))
	{ 
		print "[common] vecNormDiff() ERROR: length mismatch! l1:$#{@$l1}, l2:$#{@$l2}\n";
		return -1; }
	
	my $norm = 0;
	for(my $i=0; $i<scalar(@$l1); $i++)
	{
		#print "rowElt = $rowElt\n";
		if($p==0)
		{ $norm = max($norm, abs($$l1[$i]-$$l2[$i])); }
		else
		{ $norm += abs($$l1[$i]-$$l2[$i]) ** $p; }
	}
	if($p>0)
	{ $norm = $norm ** (1.0/$p); }
	return $norm;
}

# Given a matrix in column-major order, computes the sum of each column and 
# returns this sum vector
sub mtxColSum
{
	my ($rows, $cols, $mtx) = @_;

	my @sumVec = ();
	for(my $c = 0; $c<$cols; $c++)
	{ push(@sumVec, 0); }
	
	my $i=0;
	foreach my $column (@$mtx)
	{
		foreach my $colElt (@$column)
		{
			$sumVec[$i]+=$colElt;
		}
		$i++;
	}
	
	return @sumVec;
}


# Given a matrix in column-major order, computes the p-moment of each column and 
# returns this vector
sub mtxColMoment
{
	my ($rows, $cols, $mtx, $p, $indent) = @_;

	my @momentVec = ();
	for(my $c = 0; $c<$cols; $c++)
	{ push(@momentVec, 0); }
	
	my $i=0;
	foreach my $column (@$mtx)
	{
		foreach my $colElt (@$column)
		{
			if($p == 1)
			{ $momentVec[$i]+=$colElt; }
			else
			{ $momentVec[$i]+=$colElt**$p; }
		}
		if($p != 1)
		{ $momentVec[$i] **= 1/$p; }
		$i++;
	}
	
	return @momentVec;
}

# Multiplies the given vector by the given scalar, returning the resulting vector
sub vecScalMult
{
	my ($vec, $scal, $indent) = @_;

	my $res = [];
	foreach my $v (@$vec)
	{ push(@$res, $v*$scal); }
	
	return @$res;
}

sub vecScalMultRef
{
	my ($vec, $scal, $indent) = @_;

	my $res = [];
	foreach my $v (@$vec)
	{ push(@$res, $v*$scal); }
	
	return $res;
}

# Returns a reference to the identity matrix of the given size
sub identityMtx
{
	my ($size) = @_;
	
	my @mtx=();
	for(my $r=0; $r<$size; $r++)
	{
		my @col=();
		for(my $c=0; $c<$size; $c++)
		{ 
			if($r==$c)
			{ push(@col, 1); }
			else
			{ push(@col, 0); }
		}
		push(@mtx, \@col);
	}
	return \@mtx;
}

# Returns reference to a matrix of the given dimensions where every element has the given value.
sub constMtx
{
	my ($rows, $cols, $val) = @_;
	
	my @mtx=();
	for(my $c=0; $c<$cols; $c++)
	{
		my @col=();
		for(my $r=0; $r<$rows; $r++)
		{ push(@col, $val); }
		push(@mtx, \@col);
	}
	return ($rows, $cols, \@mtx);
}

# Adds matrixes A and B, storing the result into A
sub mtxAddAccum
{
	my ($rows, $cols, $A, $B) = @_;
	
	for(my $r=0; $r<scalar(@$A); $r++)
	{
		for(my $c=0; $c<scalar(@$A); $c++)
		{ $$A[$c][$r] += $$B[$c][$r]; }
	}
}

# Multiplies matrixes A(mxn) and B(nxp), returning a reference to the result, as a (rows, cols, matrix reference) triple
sub mtxMult
{
	my ($m, $n, $p, $A, $B) = @_;

	my ($rows, $cols, $C) = constMtx($m, $p, 0);
	if($rows != $m) { die "[common] mtxMult ERROR: Mismatched dimensions m=$m but matrix C has $rows rows!"; }
	if($cols != $p) { die "[common] mtxMult ERROR: Mismatched dimensions p=$p but matrix C has $cols columns!"; }

	for(my $i=0; $i<$m; $i++)
	{
		for(my $k=0; $k<$p; $k++)
		{
			for(my $j=0; $j<$n; $j++)
			{ $$C[$k][$i] += $$A[$j][$i] * $$B[$k][$j];}
		}
	}

	return ($rows, $cols, $C);
}

# Returns a string representation of this matrix as a table. The representation
# is blocked into squares of size ($blockSize x $blockSize), with the printed value
# for each block being the average value of all the elements in the block.
sub mtx2Str
{
	my ($mtx, $blockSize, $indent) = @_;
	
	#my $blockSize=218;
	my $out = "";
	
	my $firstCol = $$mtx[0];
	for(my $row=0; $row<scalar(@$firstCol); $row+=$blockSize)
	{
		if($row>0)
		{ $out .= $indent; }
		for(my $col=0; $col<scalar(@$mtx); $col+=$blockSize)
		{
			my $blockSum=0;
			my ($i, $j);
			for($i=0; $i<$blockSize && ($row+$i)<scalar(@$firstCol); $i++)
			{
				for($j=0; $j<$blockSize && ($col+$j)<scalar(@$mtx); $j++)
				{ $blockSum+=$$mtx[$col+$j][$row+$i]; }
			}
			$blockSum/=($i*$j);
			$out .= "$blockSum ";
		}
		$out .= "\n";
	}
	return $out;
}

# Given two matrixes, concatenates matrix $mtx2 to the columns of matrix $mtx1.
#    Returns $mtx1.
# Aborts if the two matrixes have different numbers of columns or if any columns
#    have different numbers of rows.
sub mtxRowCat
{
	my ($mtx1, $mtx2, $indent) = @_;
	my @norms = ();
	
	# If $mtx1 is empty, create it and make sure it has as many columns as $mtx2
	if(scalar(@$mtx1)==0) {
		$mtx1 = [];
		foreach my $col (@$mtx2)
		{ push(@$mtx1, []); }
	}
	
	# Abort if the two matrixes have different numbers of columns
	if(scalar(@$mtx1) != scalar(@$mtx2))
	{ confess("[common] mtxRowCat() ERROR: matrixes have different numbers of columns: #mtx1=".scalar(@$mtx1)." #mtx2=".scalar(@$mtx2)."!"); }
	
	# If both matrixes are empty, we're done
	if(scalar(@$mtx1)==0) { return $mtx1; }
	
	# Verify that all columns of matrixes 1 and 2 have the same number of rows
	{
		my $mtx1Rows = scalar(@{$mtx1->[0]});
		my $mtx2Rows = scalar(@{$mtx1->[0]});
		
		# Iterate through the columns of both matrixes
		for(my $i=1; $i<scalar(@$mtx1); $i++) {
			if(scalar(@{$mtx1->[0]}) != scalar(@{$mtx1->[$i]})) { confess("[common] mtxRowCat() ERROR: column $i of mtx1 has ".scalar(@{$mtx1->[$i]})." rows while column 0 has ".scalar(@{$mtx1->[0]})." rows!"); }
			if(scalar(@{$mtx2->[0]}) != scalar(@{$mtx2->[$i]})) { confess("[common] mtxRowCat() ERROR: column $i of mtx2 has ".scalar(@{$mtx2->[$i]})." rows while column 0 has ".scalar(@{$mtx2->[0]})." rows!"); }
		}
	}
	
	# Append columns of $mtx2 to $mtx1
	# Iterate through the columns of both matrixes
	for(my $i=0; $i<scalar(@$mtx1); $i++)
	{ push(@{$mtx1->[$i]}, @{$mtx2->[$i]}); }
	
	return $mtx1;
}


# Matrix Norms
# Returns the p-norm of the difference between the two matrixes 
sub mtxNormDiff
{
	my ($p, $m1, $m2, $rows, $cols) = @_;
	#print "mtxNormDiff($p, $m1, $m2, $rows, $cols)\n";
	
	my $norm = 0;
	for(my $c=0; $c<$cols; $c++)
	{
		for(my $r=0; $r<$rows; $r++)
		{
			if($p==-1)
			{ $norm = max($norm, abs($$m1[$c][$r]-$$m2[$c][$r])); }
			elsif($p==0)
			{ if($$m1[$c][$r] != $$m2[$c][$r]) { $norm++; } }
			elsif($p==1)
			{ $norm += abs($$m1[$c][$r]-$$m2[$c][$r]); }
			else
			{ $norm += abs($$m1[$c][$r]-$$m2[$c][$r]) ** $p; }
		}
	}
	if($p>1)
	{ $norm = $norm ** (1.0/$p); }
	return $norm;
}

# Returns the p-norm of the given matrix
sub mtxNorm
{
	my ($p, $mtx, $rows, $cols) = @_;
	#print "mtxNorm($p, $m1, $m2, $rows, $cols)\n";
	
	my $norm = 0;
	for(my $c=0; $c<$cols; $c++)
	{
		for(my $r=0; $r<$rows; $r++)
		{
			if($p==-1)
			{ $norm = max($norm, abs($$mtx[$c][$r])); }
			elsif($p==0)
			{ if($$mtx[$c][$r] != 0) { $norm++; } }
			elsif($p==1)
			{ $norm += abs($$mtx[$c][$r]); }
			else
			{ $norm += abs($$mtx[$c][$r]) ** $p; }
		}
	}
	if($p>1)
	{ $norm = $norm ** (1.0/$p); }
	return $norm;
}

# Matrix Log-Norms

# Returns the signed log of the given value
sub signedLog
{
	my ($val, $base) = @_;
	
	#print "$val => ",sign($val)*log(abs($val))/log($base),"\n";
	return sign($val)*log(abs($val))/log($base);
}

# Returns the p-norm of the difference between the two matrixes 
sub mtxLogNormDiff
{
	my ($p, $base, $m1, $m2, $rows, $cols) = @_;
	#print "mtxNormLogDiff($p, $base, $m1, $m2, $rows, $cols)\n";
	
	my $norm = 0;
	for(my $c=0; $c<$cols; $c++)
	{
		for(my $r=0; $r<$rows; $r++)
		{
			if($p==-1)
			#{ $norm = max($norm, abs(signedLog($$m1[$c][$r], $base)-signedLog($$m2[$c][$r], $base))/signedLog($$m1[$c][$r], $base)); }
			{ $norm = max($norm, abs(signedLog($$m1[$c][$r], $base)-signedLog($$m2[$c][$r], $base)), $base); }
			elsif($p==0)
			{ if($$m1[$c][$r] != $$m2[$c][$r]) { $norm++; } }
			elsif($p==1)
			#{ $norm += abs(signedLog($$m1[$c][$r], $base)-signedLog($$m2[$c][$r], $base))/signedLog($$m1[$c][$r], $base); }
			{ $norm += abs(signedLog($$m1[$c][$r], $base)-signedLog($$m2[$c][$r], $base)); }
			else
			#{ $norm += (abs(signedLog($$m1[$c][$r], $base)-signedLog($$m2[$c][$r], $base))/signedLog($$m1[$c][$r], $base)) ** $p; }
			{ $norm += abs(signedLog($$m1[$c][$r], $base)-signedLog($$m2[$c][$r], $base)) ** $p; }
		}
	}
	if($p>1)
	{ $norm = $norm ** (1.0/$p); }
	return $norm;
}


# Returns the p-norm of the difference between the two matrixes 
sub mtxLogNorm
{
	my ($p, $base, $mtx, $rows, $cols) = @_;
	#print "mtxLogNorm($p, $base, $mtx, $rows, $cols)\n";
	
	my $norm = 0;
	for(my $c=0; $c<$cols; $c++)
	{
		for(my $r=0; $r<$rows; $r++)
		{
			#print "$$mtx[$c][$r] => signedLog($$mtx[$c][$r], $base)=",signedLog($$mtx[$c][$r], $base),"\n";
			if($p==-1)
			{ $norm = max($norm, abs(signedLog($$mtx[$c][$r], $base)), $base); }
			elsif($p==0)
			{ if($$mtx[$c][$r] != 0) { $norm++; } }
			elsif($p==1)
			#{ $norm += abs(signedLog($$mtx[$c][$r], $base)-signedLog($$m2[$c][$r], $base))/signedLog($$mtx[$c][$r], $base); }
			{ $norm += abs(signedLog($$mtx[$c][$r], $base)); }
			else
			#{ $norm += (abs(signedLog($$mtx[$c][$r], $base)-signedLog($$m2[$c][$r], $base))/signedLog($$mtx[$c][$r], $base)) ** $p; }
			{ $norm += abs(signedLog($$mtx[$c][$r], $base)) ** $p; }
		}
	}
	if($p>1)
	{ $norm = $norm ** (1.0/$p); }
	return $norm;
}

#############################
###### PARALLELIZATION ######
#############################


# Runs a set of tasks in parallel, each of them getting their own process. Returns the results of the tasks
# $taskGenFunc - Function that generates the tasks to be executed (a task is described using a scalar). Called with arguments @$taskGenArgs.
# $workerFunc - Function that takes in a task description and arguments @$workerArgs and returns a pair ($res, $val), 
#        where $res is the success status of the computation (may be $common::success, $common::failRetry, $common::failRegenerate 
#        or $common::failFinal) and $val is a scalar containing the results of the computation. 
# $tmpDir - a temporary directory that this function will use to store intermediate data
# Example:
# my $results = parallelSub_Processes(
# 	sub {
# 		my ($indent) = @_;
# 		my @tasks;
# 		for(my $i=0; $i<10; $i++)
# 		{ push(@tasks, $i); }
# 		return \@tasks;
# 	}, [],
# 	sub {
# 		my ($task, $indent) = @_;
# 		print "${indent}task $task, process $$\n";
# 		if($task%2 == 0)
# 		{ return ($common::failFinal, $task+1); }
# 		else
# 		{ return ($common::success, $task+1); }
# 	}, [],
# 	"tmpDir",
# 	"....");
# 
# print "results=",list2Str($results),"\n";
# foreach my $r (@$results) { 
# 	print "r=",hash2Str($r),"\n";
# }
sub parallelSub_Processes
{
	my ($taskGenFunc, $taskGenArgs, $workerFunc, $workerArgs, $tmpDir, $indent) = @_;
	
	# Make sure that the temporary directory actually exists
	system "mkdir -p $tmpDir";
	
	# Generate the tasks
	my $tasks = $taskGenFunc->(@$taskGenArgs, $indent."    ");
	
	my @pids = ();
	my $i=0;
	foreach my $task (@$tasks) {
		#print "Spawning task $task\n";
		
		my $pid = fork();
		push(@pids, $pid);
		if (not defined $pid) { confess("[common] parallelSub_Processes() ERROR calling fork: resources not avilable!"); }
		elsif ($pid == 0) {
			#print "${indent}################ Task $task ################\n";
			my ($res, $val) = $workerFunc->($task, @$workerArgs, $indent."    ");
			#print "${indent}Task $task: res=$res, val=$val\n";
			if($res != $common::success)
			{ 
				#print "${indent}   Task $task writing to \"$tmpDir/task_${i}.Invalid\".\n";
				system "echo '$res' > $tmpDir/task_${i}.Invalid"; }
			else {
				#print "${indent}   Task $task writing to \"$tmpDir/task_${i}\".\n";
				open(my $f, ">$tmpDir/task_${i}") || confess("[common] parallelSub_Processes() ERROR opening file \"$tmpDir/task_${i}\" for writing!");
				nstore_fd [$val], $f;
				close($f);
			}
			
			#print "Child $$ Done, val=$val, task $i\n";
			#print "ls -l $tmpDir/task_${i}*\n";
			#system "ls -l $tmpDir/task_${i}*";
			# The child is done. It can now exit
			exit(0);
		}
		$i++;
	}
	
	#print "${indent}----- Joining -----\n";
	
	# The parent waits for all the processesto complete
	foreach my $pid (@pids)
	{ waitpid($pid, 0); }
	
	#print "${indent}======================================\n";
	
	#print "ls -l $tmpDir\n";
	#system "ls -l $tmpDir";
	
	my @results=();
	$i=0;
	foreach my $pid (@pids) {
		# If the current task was successfully processed
		if(-e "$tmpDir/task_${i}") {
			open(my $f, "<$tmpDir/task_${i}") || confess("[common] parallelSub_Processes() ERROR opening file \"$tmpDir/task_${i}\" for reading!");
			my $taskResult = ${retrieve_fd($f)}[0];
			#print "${indent}taskResult=",obj2Str($taskResult, $indent."    "),"\n";
			close($f);
			
			push(@results, {res=>$common::success, val=>$taskResult});
			
			# Remove the current tasks's file now that it has been read
			unlink("$tmpDir/task_${i}");
		}
		# Else, if there was an error
		elsif(-e "$tmpDir/task_${i}.Invalid") {
			open(my $f, "<$tmpDir/task_${i}.Invalid") || confess("[common] parallelSub_Processes() ERROR opening file \"$tmpDir/task_${i}.Invalid\" for reading!");
			my $taskResult = <$f>;
			close($f);
			
			push(@results, {res=>$common::failFinal, val=>$taskResult});
			
			# Remove the current tasks's file now that it has been read
			unlink("$tmpDir/task_${i}.Invalid");
		}
		else
		{ confess("[common] parallelSub_Processes() ERROR: cannot find neither \"$tmpDir/task_${i}\" nor \"$tmpDir/task_${i}.Invalid\" in temporary directory \"$tmpDir\"!"); }
		
		$i++;		
	}
	
	return \@results;
}

###############################
###### PARAMETER PASSING ######
###############################

# Checks whether the given arguments hash is properly formatted and returns a list of the argument values.
#    $args: hash that maps variable names to variable values
#    $argReqs: hash of {n=>varName, v=>defaultValue} pairs. varName identifies the name of an argument variable. 
#       defaultValue identifies its default value if any. defaultValue may be set to undef and this can be useful
#          to implement default parameter passing. Suppose foo() takes an argument it will pass to bar(). bar() takes
#          an argument that it has a default value for. foo() takes this argument from its callers but doesn't know
#          what default to set it to. If it chooses undef as the default, and the caller doesn't provide a value for this
#          argument, it will be set to undef. Then, when foo passes this argument to bar(), bar()'s default value will
#          override the undef, providing bar() with the correct default without forcing foo() to be aware of it.
#          This scheme works through multiple levels of function calls before the final call to bar().
# The function checks that all the arguments with undefined values are present in args. Further, it returns 
#    a list that contains the values of the variables in the same order as they appear in argReqs. If an argument
#    variable doesn't appear in args but has a definition in the v field in argReqs, this default value is returned
#    for that variable.
sub getHashArgs
{
	my ($args, $argReqs, $indent) = @_;

	if(not defined $args)       { confess("ERROR: arguments object is undefined!"); }
	if(not defined $argReqs)    { confess("ERROR: argument neededArgNames is undefined!"); }
	if(ref $args ne "HASH")     { confess("ERROR: arguments object is not a hash!"); }
	if(ref $argReqs ne "ARRAY") { confess("ERROR: argument neededArgNames is not a list!"); }
	
	# Make sure that @$argReqs contains {n=>, v=>} hashes with n mandatory, v optional and nothing else
	my $aIdx=0;
	foreach my $a (@$argReqs) {
		if(not defined $a->{n}) { confess("ERROR: argument index $aIdx is missing the \"n\" field!"); }
		foreach my $k (keys %$a)
		{ if($k ne "n" && $k ne "v") { confess("ERROR: argument index $aIdx has an unknown field named \"$k\"!"); } }
		$aIdx++;
	}
	
	# First look for variables that were included in $args but not requested in $argReqs
	#my $argsStr = "{";
	my %argsCopy = %$args;
	foreach my $x (@$argReqs) {
		delete $argsCopy{$x->{n}};
		#if($i>0) { $argsStr .= ", "; }
		#if(defined $val)
		#{ $argsStr .= "$name = $val"; }
		#else
		#{ $argsStr .= "$name = UNDEFINED"; }
	}
	#$argsStr .= "}";
	if(scalar(keys %argsCopy) > 0) { confess("ERROR: arguments list incorrect: Extra arguments that were not needed=[".list2StrSep([keys %argsCopy], ", ")."]."); }
	
	# Then pull together the list of argument values, checking that all the arguments in @$argReqs actually appear in $args
	my @argVals = ();
	foreach my $x (@$argReqs) {
		# If %$args does not contain a mapping for this variable name
		if(not defined $args->{$x->{n}}) {
			# If there is a default value in %$argReqs (it may be undef), use it
			if(exists $x->{v}) {
				push(@argVals, $x->{v});
			# If there is no default then this argument is mandatory. Abort.
			} else {
				{ confess("ERROR: argument \"$x->{n}\" missing from arguments=",obj2Str($args, ""),"!"); }
			}
		# If $args does have a mapping for this variable name, use the corresponding value
		} else {
			push(@argVals, $args->{$x->{n}});
		}
	}
	return @argVals;
}

return 1;
