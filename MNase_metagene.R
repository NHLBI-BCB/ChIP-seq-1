rm(list=ls())
#--Define data file directory:
setwd("/Users/Raga/Dropbox/Documents/Stem_cell_epigenetics/MNase/")

#--Read in table of data (from Sanderson et al. 2006):
# This refers to a sample of 20 clusters of galaxies with Chandra X-ray data
R <- read.table("MNase-enhdY1-R.txt", sep="\t", header=TRUE)
dY <- read.table("MNase-enhdY1-dY.txt", sep="\t", header=TRUE)
dYKO <- read.table("MNase-enhdY1-dYKO.txt", sep="\t", header=TRUE)
#nCC <- read.table(paste(dir, "mean_Tprofile-nCC.txt", sep="/"), header=TRUE)

#--Load extra library:
## if not already installed, then run:
# install.packages("ggplot2")
require(ggplot2)

#--Combine datasets into a single data frame:
R$type <- "R"
dY$type <- "dY"
dYKO$type <- "dYKO"
A <- rbind(R,dY,dYKO)

#--Define axis labels:
xlabel <- "bp"
ylabel <- "Relative Protection"

p <- ggplot(data=A, aes(x=bp, y=dY1.ave, ymin=dY1.lower, ymax=dY1.upper, fill=type, linetype=type)) + 
    geom_line() + 
    geom_ribbon(alpha=0.5) + 
    xlab(xlabel) + 
    ylab(ylabel) +
    scale_fill_manual(values = c("gold3","green3", "red3")) +
    theme_bw() +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
                    panel.background = element_blank(), axis.line = element_line(colour = "black"))
p

ggsave(p, file="dY1MNase.pdf", width=8, height=4.5)

