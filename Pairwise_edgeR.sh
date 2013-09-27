#!/bin/bash

usage () {
  echo "usage: $0 [-o <output>] [-c <name>] [-x <#>] [-t <name>] [-y <#>] [-f <file1>] [-r <path>] "
  echo "Required parameters:"
  echo "-o       The name for the output file"
  echo "-c       The name for the control condition"
  echo "-x       The number of replicates for the control condition"
  echo "-t       The name for the test condition"
  echo "-y       The number of replicates for the test condition"
  echo "-f 		 The tab-delimited total count file"
  echo "-r       The path to Pairwise_edgeR.R"
  echo ""
  echo "The required parameters must precede the files to be joined, listed with the"
  echo "  control conditions followed by the test conditions. See example below."
  echo ""
  echo "Example:"
  echo "$0 -o Example -c healthy -x 3 -t disease -y 3 all.counts.txt"
}

# Read in the important options
while getopts ":o:h:c:x:t:y:f:" option; do
  case "$option" in
    o)  OUT_PFX="$OPTARG" ;;
    c)  CONTROL_PFX="$OPTARG" ;;
    x)  CONTROL_REPS="$OPTARG" ;;
    t)  TEST_PFX="$OPTARG" ;;
    y)  TEST_REPS="$OPTARG" ;;
	f)	FILE="$OPTARG" ;;
	r)	PATHTO="$OPTARG" ;;
    h)  # it's always useful to provide some help 
        usage
        exit 0 
        ;;
    :)  echo "Error: -$option requires an argument" 
        usage
        exit 1
        ;;
    ?)  echo "Error: unknown option -$option" 
        usage
        exit 1
        ;;
  esac
done    
shift $(( OPTIND - 1 ))

# Do some error checking to make sure parameters are defined
if [ -z "$OUT_PFX" ]; then
  echo "Error: you must specify an output prefix for your file using -o"
  usage
  exit 1
fi

if [ -z "$CONTROL_PFX" ]; then
  echo "Error: you must specify the name for your control"
  echo "using -c"
  usage
  exit 1
fi

if [ -z "$CONTROL_REPS" ]; then
  echo "Error: you must specify the number of replicates for your control"
  echo "condition using -x"
  usage
  exit 1
fi

if [ -z "$TEST_REPS" ]; then
  echo "Error: you must specify the number of replicates for your test"
  echo "condition using -y"
  usage
  exit 1
fi

if [ -z "$TEST_PFX" ]; then
  echo "Error: you must specify the number of replicates for your test"
  echo "condition using -t"
  usage
  exit 1
fi
if [ -z "$FILE" ]; then
  echo "Error: you must specify the path to the count file"
  echo "using -f"
  usage
  exit 1
fi


# Print the different prefixes, conditions, and number of replicates
date > $OUT_PFX.log.txt
echo "" >> $OUT_PFX.log.txt 2>&1
echo "Output file prefix:             $OUT_PFX" >> $OUT_PFX.log.txt 2>&1
echo "Control condition name:         $CONTROL_PFX" >> $OUT_PFX.log.txt 2>&1
echo "Replicates for control:         $CONTROL_REPS" >> $OUT_PFX.log.txt 2>&1
echo "Test condition name:            $TEST_PFX" >> $OUT_PFX.log.txt 2>&1
echo "Replicates for test condition:  $TEST_REPS" >> $OUT_PFX.log.txt 2>&1
echo "" >> $OUT_PFX.log.txt 2>&1

# Running DESeq through my DESeq R script using established variables and 
#     the newly joined raw count file
echo "Running DESeq on $FILE" >> $OUT_PFX.log.txt 2>&1
Rscript $METARNASEQDIR/Pairwise_edgeR.R $FILE $OUT_PFX $CONTROL_PFX $CONTROL_REPS $TEST_PFX $TEST_REPS >> $OUT_PFX.log.txt 2>&1

exit
