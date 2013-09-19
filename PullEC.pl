#!/usr/bin/env perl

sub usage();
if ($ARGV[0] =~ /-h/ || $ARGV[0] =~ /--help/) {
		usage();
}

while (<STDIN>) {
	chomp;
	print;
	@line = split(/\t/);
	undef($locus_tag);
	if ($line[8] =~ /;old_locus_tag=([^;]+)/) {
		$locus_tag = $1;
	}
	elsif ($line[8] =~ /;locus_tag=([^;]+)/) {
		$locus_tag = $1;
	}
	if (defined $locus_tag) {
		`wget "http://www.kegg.jp/dbget-bin/www_bfind_sub?dbkey=genes&keywords=$locus_tag" 2> /dev/null`;
		open SEARCHRES, "www_bfind_sub?dbkey=genes&keywords=$locus_tag" or die "Unable to open file www_bfind_sub?dbkey=genes&keywords=$locus_tag for reading data: $!\n";
		undef($gene);
		while (($html = <SEARCHRES>) && !(defined $gene)) {
			$matchstring = "<div style=\"width:600px\"><a href=\"\\/dbget-bin\\/www_bget\\?(...:$locus_tag)\">[^<]+<";
			if ( $html =~ /$matchstring/ ) {
				$gene = $1;
			}
		}
		if (defined $gene) {
			`wget "http://www.kegg.jp/dbget-bin/www_bget?$gene" 2> /dev/null`;
			open GENEREC, "www_bget?$gene" or die "Unable to open file www_bget?$gene for reading data: $!\n";
			while ($geneline = <GENEREC>) {
				if ( $geneline =~ /<nobr>Orthology<\/nobr>/ ) {
					$nextline = <GENEREC>;
					print "\t".join(';', $nextline =~ /\[EC:<a href="\/dbget-bin\/www_bget\?[^"]+">([^<]+)</g);
				}
				elsif ( $geneline =~ /<nobr>Pathway<\/nobr>/ ) {
					$nextline = <GENEREC>;
					print "\t".join(';', $nextline =~ /<td align="left"><div>([^<]+)</g);
				}
				elsif ( $geneline =~ /<nobr>Class<\/nobr>/ ) {
					last;
				}
			}
			close GENEREC;
			unlink("www_bget?$gene");
		}
		close SEARCHRES;
		unlink("www_bfind_sub?dbkey=genes&keywords=$locus_tag");
	}
	print "\n";
}

sub usage() {
print<<EOF;
PullEC.pl, by Keith H. Turner (khturner\@utexas.edu)

This program takes a GFF file from GenomeMerge.pl on STDIN, searches http://www.kegg.jp for the locus_tag and returns a new GFF file with EC and Kegg pathway information on STDOUT.

EOF
exit 1;
}
