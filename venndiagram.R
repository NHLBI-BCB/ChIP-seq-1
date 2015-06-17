library(grid)
#libraray(VennDiagram)
library(venneuler)
vd <- venneuler(c(Brg1=12630, HDAC1=1639, Foxd3=626, "Brg1&HDAC1"=3755, "HDAC1&Foxd3"=20, "Brg1&Foxd3"=1588,
                  "Brg1&HDAC1&Foxd3"=825))
#vd <- venneuler(c(Brg1=28796, HDAC1=10423, Foxd3=3677, "Brg1&HDAC1"=14356, "HDAC1&Foxd3"=201, "Brg1&Foxd3"=1467,
                  "Brg1&HDAC1&Foxd3"=1655),lables="FALSE")
vd$labels <- rep("", length(vd$labels)) 
plot(vd)

#draw.triple.venn(47929, 26635, 6999, 16020, 1540, 2934, 1199, scaled=TRUE)
                 category = rep("", 3), rotation = 1, reverse = FALSE, euler.d = TRUE,
                 scaled = TRUE, lwd = rep(2, 3), lty = rep("solid", 3),
                 col = rep("black", 3), fill = NULL, alpha = rep(0.5, 3),
                 label.col = rep("black", 7), cex = rep(1, 7), fontface = rep("plain", 7),
                 fontfamily = rep("serif", 7), cat.pos = c(-40, 40, 180),
                 cat.dist = c(0.05, 0.05, 0.025), cat.col = rep("black", 3),
                 cat.cex = rep(1, 3), cat.fontface = rep("plain", 3),
                 cat.fontfamily = rep("serif", 3),
                 cat.just = list(c(0.5, 1), c(0.5, 1), c(0.5, 0)), cat.default.pos = "outer",
                 cat.prompts = FALSE, rotation.degree = 0, rotation.centre = c(0.5, 0.5),
                 ind = TRUE, sep.dist = 0.05, offset = 0)

vd <- venneuler(c(A=0.3, B=0.3, C=1.1, "A&B"=0.1, "A&C"=0.2, "B&C"=0.1 ,"A&B&C"=0.1))
plot(vd)

