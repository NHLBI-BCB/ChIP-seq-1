setwd("C:/Users/Raga/Dropbox/Documents/Stem_cell_epigenetics/ChIP_seq/Peaksoverlap/")
#http://stats.stackexchange.com/questions/52004/overlapping-sets-3-significance-test
#data<-read.table("overlapchi.txt",sep="\t",header=TRUE,na.rm=TRUE)
#three-way contingency table for Foxd3, HDAC1 and Brg1
#let Foxd3=A, Brg1=B and HDAC1=C
mytable<-array(c(825,1588,20,626,3755,12630,1639,159350),dim=c(2,2,2),dimnames=list(Is_C=c('yes','no'),Is_B=c('yes','no'),Is_A=c('yes','no')))
chisq.test(mytable)
mantelhaen.test(mytable)
mytable2<-data.matrix(mytable)
fisher.test(mytable2)
