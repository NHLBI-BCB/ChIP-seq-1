#obtaining beadarray package in R
source("http://bioconductor.org/biocLite.R")
biocLite("beadarray")
rm(list=ls())
#load package
library("beadarray")
#set working directory and load files
setwd("C:/Users/Raga/Dropbox/for_Ron/Sall4_Data/RK_Analysis/Combat/")
dataFile="OSK_andSall4_reprogram_data_postcombat_triage_allips.csv"
sampleSheet="SampleSheet_OSK_and_Sall4profiling_triage.csv"
#testing Archana's data
#setwd("/Users/Raga/Documents/Stem cell epigenetics/RNA profiling/Archana data")
#dataFile="ES_expt.csv"
#sampleSheet="SampleSheet_ES.csv"
#read data file
ArrayData = readBeadSummaryData(dataFile=dataFile, sampleSheet=sampleSheet, ProbeID = "ProbeID", sep=",", skip=1)
par(mfrow=c(1,2))
#draw boxplots
boxplot(as.data.frame(log2(exprs(ArrayData))), las=2,outline=FALSE,ylab="log2(intensity)")
#normalize and re-draw boxplots
#ArrayData.norm<-normaliseIllumina(ArrayData,method="quantile",transform="log2")
ArrayData.norm<-normaliseIllumina(ArrayData,method="quantile",transform="none")
boxplot(as.data.frame(log2(exprs(ArrayData.norm))),las=2,outline=FALSE,ylab="log2(intensity)")
#write.table(exprs(ArrayData.norm),"arch_data.txt", sep="\t", quote=FALSE)
write.table(exprs(ArrayData.norm),"OSK_andSall4_reprogram_data_combat_triage_quantnorm_allips.txt", sep="\t", quote=FALSE)
#run differential expression to identify genes
library(limma)
#ArrayData.norm=read.table("combat_reprog_data_triage.txt",row.names=1,sep="\t",header=T,na.strings = "NA")
rna <- factor(pData(ArrayData.norm)[, "Sample_Group"])
design<-model.matrix(~0+rna)
colnames(design)<-levels(rna)
aw <- arrayWeights(exprs(ArrayData.norm), design)
fit <- lmFit(exprs(ArrayData.norm), design, weights = aw)
contrasts <- makeContrasts(Yellow - Green, levels = design)
contr.fit <- eBayes(contrasts.fit(fit, contrasts))
diff<-topTable(contr.fit, coef=NULL, number=25699)
write.table(diff,"pval_YellowOSK_vs_GreenOSK.txt", sep="\t", quote=FALSE)