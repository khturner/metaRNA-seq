#!/bin/bash

IN_FQ=$1
OUT_PFX=$2
ASSEMBLY=$3
THREADS=$4

# show usage if we don't have 4 command-line arguments
if [ "$THREADS" == "" ]; then
	echo ""
	echo "MapCount_RNASeq, by Peter A. Jorth (pjorth at utexas dot edu), 2013"
	echo ""
    echo "-----------------------------------------------------------------"
    echo "Align a trimmed fastq file with Bowtie to a reference metagenome,"
    echo "and count the number of reads mapping to a feature with HT-Seq."
    echo "The output is a read alignment sam file and a count file."
    echo " "
    echo "USAGE: MapCount_RNASeq.sh in_file out_pfx assembly threads(x)"
    echo " "
    echo "  in_file   Path of the trimmed input fastq file."        
    echo "  out_pfx   Desired prefix of output files."
    echo "  assembly  Prefix for assembly."
    echo "  threads   1 = 1 processing thread; 2 = 2 processing threads, etc."
    echo " "
    echo "Example:"
    echo "  MapCount_RNASeq.sh my.fastq Library1 META 16"
    exit 1
fi

# general function that exits after printing its text argument
#   in a standard format which can be easily grep'd.
err() {
  echo "$1...exiting"
  exit 1 # any non-0 exit code signals an error
}

# function to check return code of programs.
# exits with standard message if code is non-zero;
# otherwise displays completiong message and date.
#   arg 1 is the return code (usually $?)
#   arg2 is text describing what ran
ckRes() {
  if [ "$1" == "0" ]; then
    echo "..Done $2 `date`"
  else
    err "$2 returned non-0 exit code $1"
  fi
}

# function that checks if a file exists
#   arg 1 is the file name
#   arg2 is text describing the file (optional)
ckFile() {
  if [ ! -e "$1" ]; then
    err "$2 File '$1' not found"
  fi
}

# function that checks if a file exists and
#   that it has non-0 length. needed because
#   programs don't always return non-0 return
#   codes, and worse, they also create their
#   output file with 0 length so that just
#   checking for its existence is not enough
#   to ensure the program ran properly
ckFileSz() {
  ckFile $1 $2;
  SZ=`ls -l $1 | awk '{print $5}'`
  if [ "$SZ" == "0" ]; then
    err "$2 file '$1' is zero length"
  fi
}

# Looking up bowtie version for program run details
BOWTIE_VER=`bowtie2 -h | grep -m 1 Bowtie | awk '{print $4}'`

# Display how the program will be run, including
#   defaulted arguments. Do this before running
#   checks so user can see what went wrong.
echo "=================================================================" 1> $OUT_PFX.log.txt 2>&1
echo "MapCount_RNASeq.sh - `date`" >> $OUT_PFX.log.txt 2>&1
echo "  input file:        $IN_FQ" >> $OUT_PFX.log.txt 2>&1
echo "  output prefix:     $OUT_PFX" >> $OUT_PFX.log.txt 2>&1
echo "  assembly:          $ASSEMBLY" >> $OUT_PFX.log.txt 2>&1
echo "  bowtie version:    $BOWTIE_VER" >> $OUT_PFX.log.txt 2>&1
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1

# ------------------
# Error Checks
# ------------------
# Make sure the fastq file(s) exist.
ckFile "$IN_FQ" "Input fastq"

# Make sure we have found an appropriate reference
#   by checking that one of the standard files exists.
ckFile "$ASSEMBLY.1.bt2" "$ASSEMBLY Reference"

# ------------------
# The actual work!
# ------------------

# Map trimmed fastq reads to the reference genome using bowtie
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1
echo "Running bowtie2" >> $OUT_PFX.log.txt 2>&1
echo "`date`" >> $OUT_PFX.log.txt 2>&1
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1
bowtie2 -x $METARNASEQDIR/$ASSEMBLY -q -p $THREADS -k 1 -U $IN_FQ -S $OUT_PFX.sam >> $OUT_PFX.log.txt 2>&1
ckRes $? "bowtie2"
ckFileSz "$OUT_PFX.sam"
    
# Insert perl script to modify sam file to match accession number
#    i.e. change gi|XXXXXX|gb|YYYYYYY| to YYYYYYY
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1
echo "Cleaning up accession numbers in sam file for HT-Seq" >> $OUT_PFX.log.txt 2>&1
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1
perl -pe 's/gi\|.+\|\w+\|//g' $OUT_PFX.sam | perl -pe 's/\|\t/\t/g' > $OUT_PFX.clean.sam
mv $OUT_PFX.clean.sam $OUT_PFX.sam

# Count reads mapping to features using HT-Seq, a python script
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1
echo "Running HTSeq to count reads mapping to genes" >> $OUT_PFX.log.txt 2>&1
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1
htseq-count -m intersection-nonempty -t gene -i locus_tag $OUT_PFX.sam $METARNASEQDIR/$ASSEMBLY.gff > $OUT_PFX.count.txt
ckRes $? "htseq-count"
ckFileSz "$OUT_PFX.count.txt"

# If we make it here, all went well. Exit with a standard
#   message that can be easily grep'd
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1
echo "All alignment and counting tasks completed successfully!" >> $OUT_PFX.log.txt 2>&1
echo "`date`" >> $OUT_PFX.log.txt 2>&1
echo "---------------------------------------------------------" >> $OUT_PFX.log.txt 2>&1
exit 0
