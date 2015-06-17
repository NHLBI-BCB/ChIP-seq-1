rm(list=ls())
#--Define data file directory:
setwd("/Users/Raga/Dropbox/Documents/Stem_cell_epigenetics/ChIP_seq/Peaksoverlap/")
mydata <- read.table("overlapchi.txt", sep="\t", header=TRUE)
data1<-data[,1]
data2<-data[,2]
data3<-data[,3]
chisq.test(x=data1,y=data2)

rm(list=ls())
#--Define data file directory:
setwd("/Users/Raga/Dropbox/Documents/Stem_cell_epigenetics/MNase/")
mydata <- read.table("pvalues.txt", sep="\t", header=TRUE)
data<-data.matrix(mydata)
#heatmap(data,Rowv = NA, Colv = NA)
#install.packages("lattice", dependencies = TRUE)
#library(lattice)
#levelplot(data, col.regions=heat.colors)
#install.packages("gplots", dependencies = TRUE)
library(gplots)
library(RColorBrewer)
heatmap.2(data,Rowv = NA, Colv = NA, 
          trace=c("none"), key = TRUE, density.info=c("none"),
          colsep=1:ncol(data), sepcolor="white", sepwidth=c(0.1,0.1),
          col=brewer.pal(9,"Blues"))

rm(list=ls())
#--Define data file directory:
setwd("/Users/Raga/Dropbox/Documents/Stem_cell_epigenetics/MNase/")
mydata <- read.table("anova.txt", sep="\t", header=TRUE)
primers<-mydata[,1]
Rsamples<-rep("R",24)
dYsamples<-rep("dY",24)
dYKOsamples<-rep("dYKO",24)
R1data<-c(mydata[,2],mydata[,3],mydata[,4],mydata[,5],mydata[,6],mydata[,7])
R1primers<-rep(as.character(primers),6)
R1primers<-as.factor(R1primers)
R1samples<-c(as.character(Rsamples),as.character(Rsamples),
             as.character(dYsamples),as.character(dYsamples),
             as.character(dYKOsamples),as.character(dYKOsamples))
R1samples<-as.factor(R1samples)

dY1data<-c(mydata[,8],mydata[,9],mydata[,10],mydata[,11],mydata[,12],mydata[,13])
dY2data<-c(mydata[,14],mydata[,15],mydata[,16],mydata[,17],mydata[,18],mydata[,19])

anova( lm(R1data ~ R1primers*R1samples) )
anova( lm(dY1data ~ R1primers*R1samples) )
anova( lm(dY2data ~ R1primers*R1samples) )
