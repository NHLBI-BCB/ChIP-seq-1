#areaundercurve
rm(list=ls())
#setwd("/Users/Raga/Dropbox/Documents/Stem_cell_epigenetics/ChIP/AmyBrg1ChIPdata/")
setwd("C:/Users/Raga/Dropbox/2014analysis/")
#HDAC2boxp
#HDAC1boxp
data<-read.table("testhdac.txt",sep="\t",header=T,na.strings = "NA")
data2<-read.table("testhdacd.txt",sep="\t",header=T,na.strings = "NA")
#data<-read.table("expressionVSnewpeaks-boxplots.txt",sep="\t",header=T,na.strings = "NA")
#data2<-cbind(data[,7],data[,5])
#data2<-data.frame(data2)
#data3<-cbind(data[,8],data[,6])
#data3<-data.frame(data3)
dataa<-data[,3]
datab<-data2[,3]
finaldata<-data.frame(dataa,datab)
#boxplot(finaldata, outline=F, col=c("dark grey","green"))
boxplot(dataa, range=0, outline=F, col=c("black"),ylim=c(-1,3))
boxplot(datab, range=0, outline=F, col=c("dark grey"),ylim=c(-1,3))
      #ylim=c(-1,1.5))
#, ylim=c(0.4,2.0))
#boxplot(data, outline=F, col=c("black","dark green"))
boxplot(data3, range=0, outline=F, col=c("dark grey","yellow"))
#, ylim=c(0.4,2.0))
#,ylim=c(-0.1,0.1))
 
#boxplot(data1, outline=F, col=c("sky blue","maroon"))
#boxplot(data2, outline=F, col=c("sky blue","maroon"))


#dY<-read.table("dYmotifs.txt",sep="\t",header=T,na.strings = "NA")
#barplot(R$Enrich, names.arg = R$Motif, cex.names=0.7, xlab=c("Motif"), ylab=c("percent enrichment"),
#        col = gray.colors(length(unique(R$Pval)))[as.factor(R$Pval)])
#barplot(dY$Enrich, names.arg = dY$Motif, cex.names=0.7, xlab=c("Motif"), ylab=c("percent enrichment"),
#        col = gray.colors(length(unique(dY$Pval)))[as.factor(dY$Pval)])