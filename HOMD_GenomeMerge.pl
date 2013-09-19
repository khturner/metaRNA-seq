#!/usr/bin/env perl

sub usage();
sub GFF_Cleaner();
sub Get_EC();
sub EC_Pathways();
sub Tag_GFF();
sub GFF_Sort();

if ($ARGV[0] =~ /-h/ || $ARGV[0] =~ /--help/ ) { usage(); }
elsif ($ARGV[0] eq "GFF_Cleaner") { GFF_Cleaner(); }
elsif ($ARGV[0] eq "Get_EC") { Get_EC(); }
elsif ($ARGV[0] eq "EC_Pathways") { EC_Pathways(); }
elsif ($ARGV[0] eq "Tag_GFF") { Tag_GFF(); }
elsif ($ARGV[0] eq "GFF_Sort") { GFF_Sort(); }
usage();

sub GFF_Cleaner() {
	use URI::Escape;
	my $genenum = 0;
	while (<STDIN>) {
		if ($_ =~ /^#/) { print; }
		else {
			chomp;
			@line = split(/\t/);
			foreach $field (@line[0 .. 7]) { print "$field\t"; }
			@attributes = split(';', $line[8]);
			$genenum++;
			foreach $att (@attributes) {
				$att = uri_unescape($att);
				if ($att =~ /^Parent=(.+)\..+$/) { print "Name=$1;gbkey=Gene;locus_tag=$1"; }
				elsif ($att =~ /BLAST match \(swissprot\): ([^,]+)/) { print ";product=".$1; }
			}
			print "\n";
		}
	}
	exit 1;
}

sub Get_EC() {
	if (scalar (@ARGV) < 2) { usage(); }
	$genome = $ARGV[1];
    while (<STDIN>) {
    	chomp;
    	@line = split;
    	print $line[0];
    	if ($line[1] =~ /sp\|([^\|]+)\|/) { $acc = $1; }
		if (!(-f "$genome/$acc.xml")) { `wget "http://www.uniprot.org/uniprot/$acc.xml" -O $genome/$acc.xml 2> /dev/null`; }
		open SPREC, "$genome/$acc.xml" or die "Unable to open file $genome/$acc.xml for reading data: $!\n";
		@ECs = ();
		while ($SPline = <SPREC>) {
			if ( $SPline =~ /<ecNumber>([^<]+)<\/ecNumber>/ ) {
				push(@ECs, $1);
			}
			elsif ( $SPline =~ /<\/recommendedName>/ ) {
				last;
			}
		}
		if ((scalar @ECs) > 0) { print "\t".join(';', @ECs); }
		print "\n";
	}
	unlink <$genome/*.xml>;
	exit 1;
}

sub EC_Pathways() {
	if (scalar (@ARGV) < 2) { usage(); }
	$genome = $ARGV[1];
	while (<STDIN>) {
		chomp;
		@line = split(/\s/);
		print $line[0];
		$ECnums = $line[1];
		print "\t".$ECnums;
		@pathways = ();
		foreach $ECnum (split(';', $ECnums)) {
			if (!(-f "$genome/www_bget?ec:$ECnum")) { `wget "http://www.kegg.jp/dbget-bin/www_bget?ec:$ECnum" -O $genome/www_bget?ec:$ECnum 2> /dev/null`; }
			open ECREC, "$genome/www_bget?ec:$ECnum" or die "Unable to open file $genome/www_bget?ec:$ECnum for reading data: $!\n";
			while ($ECline = <ECREC>) {
				if ( $ECline =~ /<nobr>Pathway<\/nobr>/ ) {
					$nextline = <ECREC>;
					push(@pathways, $nextline =~ /<td align="left"><div>([^<]+)</g);
				}
				elsif ( $ECline =~ /<nobr>Orthology<\/nobr>/ ) {
					last;
				}
			}
			close ECREC;
		}
		if ((scalar @pathways) > 0) { print "\t".join(';', @pathways); }
		print "\n";
	}
	unlink <$genome/www_bget?ec:*>;
	exit 1;
}

sub Tag_GFF() {
	if (scalar (@ARGV) < 2) { usage(); }
	$ID_EC_Path_file = $ARGV[1];
	open ID_EC_PATH, "$ID_EC_Path_file" or die "Unable to open file $ID_EC_Path_file for reading data: $!\n";
	my $ID_EC_Path_line = <ID_EC_PATH>;
	chomp $ID_EC_Path_line;
	my @ID_EC_Path = split(/\t/, $ID_EC_Path_line);
	my $ID = @ID_EC_Path[0];
	my $EC = @ID_EC_Path[1];
	my $Path = @ID_EC_Path[2];

	while (<STDIN>) {
		if ($_ =~ /^#/) { print; }
		else {
			chomp;
			print;
			@line = split(/\t/);
			@attributes = split(';', $line[8]);
			foreach $att (@attributes) {
				if ($att =~ /^Name=(.+)/) {
					if ($1 eq $ID) {
						print "\t".$EC."\t".$Path;
						$ID_EC_Path_line = <ID_EC_PATH>;
						chomp $ID_EC_Path_line;
						my @ID_EC_Path = split(/\t/, $ID_EC_Path_line);
						$ID = @ID_EC_Path[0];
						$EC = @ID_EC_Path[1];
						$Path = @ID_EC_Path[2];
					}
				}
			}
			print "\n";
		}
	}
	close ID_EC_PATH;
	exit 1;
}

sub GFF_Sort() {
	my @gff;
	while (<STDIN>) { chomp; push @gff, [split(/\t/)]; }

	for $i (0 .. $#gff) {
		if ($gff[$i][8] =~ /^Name=[^_]+_._(\d+)_/) { unshift @{$gff[$i]}, $1; }
	}

	my @sorted = sort { $a->[0] <=> $b->[0] || $a->[4] <=> $b->[4] } @gff;

	my $prefix = "test";
	if ($sorted[0][9] =~ /^Name=([^_]+)_/) { $prefix = $1; }

	for $i (0 .. $#sorted) {
		my $tag = "c";
		if ($sorted[$i][9] =~ /^Name=[^_]+_(.)/) { $tag = $1; }
		print $prefix."_".$tag."_".$sorted[$i][0]."\t".$sorted[$i][2]."\t".$sorted[$i][3]."\t".$sorted[$i][4]."\t".$sorted[$i][5]."\t".$sorted[$i][6]."\t".$sorted[$i][7]."\t".$sorted[$i][8]."\t";
		print "ID=gene".$i.";".$sorted[$i][9];
		if ($sorted[$i][10]) { print "\t".$sorted[$i][10]; }
		if ($sorted[$i][11]) { print "\t".$sorted[$i][11]; }		
		print "\n";
	}
	exit 1;
}


sub usage() {
print<<EOF;
HOMD_GenomeMerge, by Keith H. Turner (khturner\@utexas.edu)
This is a suite of utilities used in a pipeline to merge genomes from the Human Oral Microbiome Database (http://www.homd.org).

Usage: HOMD_GenomeMerge.pl (command) [arg]

(command) is a required argument that has one of the following values:
GFF_Cleaner  -\ttakes a GFF file generated from a GenBank file from the HOMD by bp_genbank2gff on STDIN and parses and relabels the 9th field to match the GFF file notation as in GenBank proper on STDOUT.
Get_EC     -\ttakes an (ID, SwissProt Accession No.) pair on STDIN, searches UniProt for the accession number and returns (ID, EC number) on STDOUT (provide genome prefix at [arg])
EC_Pathways  -\ttakes an (ID, EC number) pair on STDIN, searches http://www.kegg.jp for the EC number and returns (ID, EC number, Kegg pathway information) on STDOUT (provide genome prefix at [arg]).
Tag_GFF    -\treads (ID, EC number, Kegg pathway information) from file [arg] and prints (EC number, Kegg pathway information) on the correct line of the GFF file read from STDIN on STDOUT
GFF_Sort    -\ttakes a GFF file generated by our HOMD annotation pipeline on STDIN, sorts it by (contig)-(position) and returns it on STDOUT.
EOF
exit 1;
}
