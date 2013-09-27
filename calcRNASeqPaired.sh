#!/bin/bash

usage () {
  echo "calcRNASeqPaired, by Peter A. Jorth (pjorth at utexas dot edu)"
  echo " "
  echo "usage: ./calcRNASeqPaired.sh [-o <output>] [-c <name>] [-x <#>] [-t <name>] [-y <#>] <file1> <file2> <file3> ... <filen> "
  echo "Required parameters:"
  echo "-o     The name for the output file"
  echo "-c     The name for the control condition"
  echo "-x     The number of replicates for the control condition"
  echo "-t     The name for the test condition"
  echo "-y     The number of replicates for the test condition"
  echo ""
  echo "The required parameters must precede the files to be joined, listed with the"
  echo "  control conditions followed by the test conditions. See examples below."
  echo ""
  echo "Example:"
  echo "./calcRNASeqPaired.sh -o Example -c Healthy -x 3 -t Disease -y 3 H1.count H2.count H3.count D1.count D2.count D3.count"

}

# Read in the important options
while getopts ":o:h:c:x:t:y:" option; do
  case "$option" in
    o)  OUT_PFX="$OPTARG" ;;
    c)  CONTROL_PFX="$OPTARG" ;;
    x)  CONTROL_REPS="$OPTARG" ;;
    t)  TEST_PFX="$OPTARG" ;;
    y)  TEST_REPS="$OPTARG" ;;
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

# Give the usage if there aren't enough parameters
if [ $# -lt 2 ] ; then
  echo "you cannot join less than 2 files"
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

i=0
k=0
for FILE in "$@"; do
	let "i += 1"
	# Remove the last 5 lines of the count file
	head -n -5 $FILE > $FILE.$i.jointmp
	# Now do the actual joining. This involves creating some temporary files
	#    that get deleted upon completion of the joining process.	
	if [ "$i" == 1 ]; then
	  # Rename the first temporary file
	  mv $FILE.$i.jointmp $OUT_PFX.$i.jointmp
	elif [ "$i" -gt 1 ]; then
	  # Join the newest temporary file with the previous
        let "j = "$i" - 1";
	  join -t $'\t' $OUT_PFX.$j.jointmp $FILE.$i.jointmp > $OUT_PFX.$i.jointmp
	else
	  echo "something went wrong during the joining"
	  exit 1  
	fi
	
	# Generate the header iteratively numbering each control and test
	#     condition and separating with tabs
    m=$i
	if [ "$m" == 1 ]; then
	  HEAD_ROW=$'\t'"$CONTROL_PFX"."$m"
	elif [ "$m" -gt 1 -a "$m" -le "$CONTROL_REPS" ]; then
	  HEAD_ROW="$HEAD_ROW"$'\t'"$CONTROL_PFX"."$m"
	elif [ "$m" -gt "$CONTROL_REPS" ]; then
	  let "k += 1"
	  HEAD_ROW="$HEAD_ROW"$'\t'"$TEST_PFX"."$k"
	fi
done

# Now double check to make sure that the number of replicates input by the
#     user match the number of files. If they don't match the program will
#     report an error message and exit.
let "NUM_COL = "$CONTROL_REPS" + "$TEST_REPS""
if [ $i != $NUM_COL ]; then
  echo "total number of replicates does match number of files"
  exit 1
fi

# Add the row to the top that adds column labels for the experimental
#    conditions.
echo "Adding header row to joined count table" >> $OUT_PFX.log.txt 2>&1
echo "$HEAD_ROW" >> $OUT_PFX.log.txt 2>&1
echo "" >> $OUT_PFX.log.txt 2>&1
echo "" >> $OUT_PFX.log.txt 2>&1
echo "$HEAD_ROW" | cat - $OUT_PFX.$i.jointmp > temp && mv temp $OUT_PFX.count.txt

echo "Cleaning up the following temporary files:" >> $OUT_PFX.log.txt 2>&1
ls *.jointmp >> $OUT_PFX.log.txt 2>&1
echo "" >> $OUT_PFX.log.txt 2>&1
rm *.jointmp

# Running EdgeR through my EdgeR R script using established variables and 
#     the newly joined raw read count file
echo "Running EdgeR on $OUT_PFX.count.txt" >> $OUT_PFX.log.txt 2>&1
Rscript $METADIR/Pairwise_edgeR.R $OUT_PFX.count.txt $OUT_PFX $CONTROL_PFX $CONTROL_REPS $TEST_PFX $TEST_REPS >> $OUT_PFX.log.txt 2>&1

exit
