#!/usr/bin/env perl

use Net::FTP;
sub usage();
unless (@ARGV == 2 && 
	($Genomes_File = $ARGV[0]) =~ /\.txt$/ && 
	($Out_Pfx = $ARGV[1]) !~ /^$/) {
		usage();
}

open GENOMES, "$Genomes_File" or die "Unable to open file $Genomes_File for reading data: $!\n";
open FNAOUT, ">$Out_Pfx.fna" or die "Unable to open file $Out_Pfx.fna for outputting data: $!\n";
open GFFOUT, ">$Out_Pfx.gff" or die "Unable to open file $Out_Pfx.gff for outputting data: $!\n";
print GFFOUT "##gff-version 3\n##GenomeMerge.pl-created metaorganism, see accompanying .fna for details\n";
$position_offset = 0;
$NCBI_FTP = Net::FTP->new("ftp.ncbi.nih.gov") or die "Cannot connect to ftp.ncbi.nih.gov: $@";
$NCBI_FTP->login("anonymous",'-anonymous@') or die "Cannot login ", $NCBI_FTP->message;

while (<GENOMES>) {
	chomp;
	@line = split(/\t/);
	$NCBI_FTP->cwd("/genbank/genomes/Bacteria/$line[0]") or die "Cannot change working directory ", $NCBI_FTP->message;
	for ($i=1; $i<=$#line; $i++) {
		if (!(-r "$line[$i].fna")) { $NCBI_FTP->get("$line[$i].fna") or die "Cannot get file ", $NCBI_FTP->message; }
		if (!(-r "$line[$i].gff")) { $NCBI_FTP->get("$line[$i].gff") or die "Cannot get file ", $NCBI_FTP->message; }
		open FNAIN, "$line[$i].fna" or die "Unable to open file $line[$i].fna for reading data: $!\n";
		print FNAOUT while (<FNAIN>);
		close FNAIN;
		
		open GFFIN, "$line[$i].gff" or die "Unable to open file $line[$i].gff for reading data: $!\n";
		while (<GFFIN>) {
			unless ($_ =~ /^#/) {
				chomp;
				@gff_line = split(/\t/);
				if ($gff_line[2] =~ /^gene$/) {
					$next = <GFFIN>;
					chomp $next;
					@next_line = split(/\t/, $next);
					if ($next_line[2] =~ /^(CDS|ncRNA)$/) {
						$next_line[8] =~ /product=([^;]+)/;
						$product = $1;
						$next_line[8] =~ /protein_id=([^;]+)/;
						$protein_id = $1;
						print GFFOUT "$gff_line[0]\t$gff_line[1]\t$gff_line[2]\t$gff_line[3]\t$gff_line[4]\t$gff_line[5]\t$gff_line[6]\t$gff_line[7]\t$gff_line[8];product=$product;protein_id=$protein_id\n";
					}
				}
			}
		}
		close GFFIN;
	}
}
close GENOMES;	
close FNAOUT;
close GFFOUT;
$NCBI_FTP->quit;

sub usage() {
print<<EOF;
GenomeMerge, by Keith H. Turner (khturner\@utexas.edu)

This program takes a tab-separated list of bacterial genome directory names (find at
ftp://ftp.ncbi.nih.gov/genbank/genomes/Bacteria/) and the associated accession numbers and joins
the .fna and the .gff files to make new .fna and .gff files specifying one "metaorganism"
encompassing all of them

usage: GenomeMerge.pl (genomes).txt (out_pfx)

Arguments:

(genomes).txt\tA tab-separated list of directory names and accession numbers
(out_pfx)\tThe prefix you want used for the output files

EOF
exit 1;
}
