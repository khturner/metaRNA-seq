#!/usr/bin/env bash

usage () {
  echo "HOMDpull, by Keith H. Turner (khturner@utexas.edu)"
  echo " "
  echo "usage: ./HOMDpull.sh (prefix)"
  echo " "
  echo "This script takes a .gbk from a dynamically-annotated genome on the Human Oral"
  echo "Microbiome Database (http://www.homd.org/index.php?&name=seqDownload&type=G)"
  echo "with prefix (prefix), generates a .fna file of the DNA sequence and a .gff file"
  echo "with EC number and KEGG pathway annotations (using the same prefix provided)."
  echo " "
  echo "Requires: (prefix).gbk and (prefix)_swisstopmatch.xls from HOMD"
  echo "Depends on: bp_seqconvert.pl (BioPerl), HOMD_GenomeMerge.pl (this package)"
  echo " "
  echo "Examples:"
  echo "./ HOMDpull.sh bext"
}

GENOME=$1
if [ -z "$GENOME" ]; then
  echo "Error: you must specify a genome prefix as a command line argument"
  usage
  exit 1
fi
if [ ! -e $GENOME.gbk ]
then
   echo "Error: $GENOME.gbk does not exist, please download it from HOMD"
   usage
   exit 1
fi
if [ ! -e ${GENOME}_swisstopmatch.xls ]
then
   echo "Error: ${GENOME}_swisstopmatch.xls does not exist, please download it from HOMD"
   usage
   exit 1
fi

bp_seqconvert.pl --from genbank --to fasta < $GENOME.gbk > $GENOME.fna
NUMFILES=$(csplit -z -n 4 -f $GENOME.gbk. $GENOME.gbk '/^\/\//+1' '{*}' | wc -l)
INDEX=0
while [ $INDEX -lt $NUMFILES ]
do
	FINDEX=$(printf "%04d" $INDEX)
	mv $GENOME.gbk.$FINDEX $GENOME.$FINDEX.gbk
	bp_genbank2gff.pl --file $GENOME.$FINDEX.gbk --stdout | grep 'BLAST' | HOMD_GenomeMerge.pl GFF_Cleaner | awk -F "\t" '{ if ($3=="CDS") $3="gene"; OFS="\t"; print; }' > $GENOME.gff.$INDEX
	let "INDEX += 1"
done
INDEX=0
rm -f $GENOME.gff
rm -f $GENOME.????.gbk
while [ $INDEX -lt $NUMFILES ]
do
	cat $GENOME.gff.$INDEX >> $GENOME.gff
	let "INDEX += 1"
done
rm -f $GENOME.gff.*

mkdir $GENOME
tail -n +2 ${GENOME}_swisstopmatch.xls | sort -V | awk '{print $3,$6;}' | HOMD_GenomeMerge.pl Get_EC $GENOME > $GENOME.locus.EC.txt
cat $GENOME.locus.EC.txt | HOMD_GenomeMerge.pl EC_Pathways $GENOME > $GENOME.ECs.Pathways.txt
rm -fr $GENOME
cat $GENOME.gff | HOMD_GenomeMerge.pl Tag_GFF $GENOME.ECs.Pathways.txt > $GENOME.kegg.unsorted.gff
cat $GENOME.kegg.unsorted.gff | HOMD_GenomeMerge.pl GFF_Sort > $GENOME.kegg.gff
rm -f $GENOME.kegg.unsorted.gff
rm -f $GENOME*.txt
rm -f $GENOME.gff
