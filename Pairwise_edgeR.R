# Tell R where to find your file with your gene count data and store the data into a 
# Read in arguments for the program: file, output prefix, conditions, and replicates
args <- commandArgs(trailingOnly=TRUE)

OUTPFX <- args[2]
OUTPFX
COND1 <- args[3]
COND1
REPS1 <- args[4]
REPS1
COND2 <- args[5]
COND2
REPS2 <- args[6]
REPS2
setwd("./")

# First load the EdgeR library into R
library(edgeR)

# read in data
rawdata <- read.delim(file=args[1])
d <- rawdata[, 2:7]
d <- DGEList(counts=d, genes=rawdata[,1])
rownames(d$counts) <- rownames(d$genes)

# normalize the read counts
d <- calcNormFactors(d)
d$samples

# Creating file name for the MDS plot
OUT1 <- print( paste( OUTPFX, "_MDSplot.png", sep=""))

#Create file to print the dispersion estimates graph 
png(file=OUT1, width=1050, height=1050)
 
#Plot the MDS for data
plotMDS(d)

# Finish making the graph
dev.off() 

# Set up the paired experimental design of the experimental samples
#    Change this depending on your experimental design set up
Patient <- factor(c(1:REPS1)),c(1:REPS2)))
Status <- factor(c(rep(COND1, REPS1),c(rep(COND2, REPS2)))
data.frame(Sample=colnames(d),Patient,Status)
design <- model.matrix(~Patient+Status)
rownames(design) <- colnames(d)
totalRows <- nrow(d)

# Estimate the dispersions for the data
d <- estimateGLMCommonDisp(d, design, verbose=TRUE)
d <- estimateGLMTrendedDisp(d, design)
d <- estimateGLMTagwiseDisp(d, design)

# Creating file name for the dispersion fit estimates
OUT2 <- print( paste( OUTPFX, "_edgeRfit.png", sep=""))

# Create file to print the dispersion estimates graph 
png(file=OUT2, width=1050, height=1050)
 
# Plot the dispersion estimates
plotBCV(d)

# Finish making the graph
dev.off() 

# Test differential expression
fit <- glmFit(d, design)

# Likelihood ratio test
lrt <- glmLRT(fit)

# Creating file name for the differential expression table
OUT3 <- print( paste( OUTPFX, "_DEedgeR.txt", sep=""))

# Save the differential expression data to a file
write.table( topTags(lrt, n=totalRows), file=OUT3, sep="\t")

# Creating file name for the differential expression table
OUT4 <- print( paste( OUTPFX, "_CPMedgeR.txt", sep=""))

# Save the differential expression data to a file
top <- rownames(topTags(lrt, n=totalRows))
write.table( cpm(d)[top,], file=OUT4, sep="\t")

