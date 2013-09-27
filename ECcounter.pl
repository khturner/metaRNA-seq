#!/usr/bin/perl

sub usage();
if ($ARGV[0] =~ /-h/ || $ARGV[0] =~ /--help/) {
		usage();
}

my $i=0;
my $pEC=0;
my $count1=0;
my $count2=0;
my $count3=0;
my $count4=0;
my $count5=0;
my $count6=0;

while (<STDIN>) {
	chomp;
	# Read each line into an array
	@line = split(/\t/);
	# Sets the first EC number
	if ($i == 0) {
		$pKO = $line[0];
		$i++;
	}
	# Adds to the EC number count if EC number is the same
	#     as the previous one.
	if ($line[0] =~ m/$pEC/) {
		$count1 += $line[1];
		$count2 += $line[2];
		$count3 += $line[3];
		$count4 += $line[4];
		$count5 += $line[5];
		$count6 += $line[6];
	}
	# If the line contains a new EC number, print the previous
	#     EC number and the total counts for that EC number
	else {
		print "$pEC\t$count1\t$count2\t$count3\t$count4\t$count5\t$count6\n";
		$count1 = $line[1];
		$count2 = $line[2];
		$count3 = $line[3];
		$count4 = $line[4];
		$count5 = $line[5];
		$count6 = $line[6];
		$pKO = $line[0];		
	}
}
# Print the last EC number and the total counts for that EC
print "$pEC\t$count1\t$count2\t$count3\t$count4\t$count5\t$count6\n";

sub usage() {
print<<EOF;
ECcounter.pl, by Peter A. Jorth (pjorth\@utexas.edu)

This program takes a large table containing EC numbers on the first field and six
read counts on the remaining 6 fields on STDIN and returns a new table with a
the total number of reads in each of the 6 fields per unique EC number on STDOUT.

EOF
exit 1;
}
