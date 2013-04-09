# This script will simply visualize and save the color bar

outdir <- "/home2/data/Projects/CWAS/age+gender/03_robustness/viz_cwas"

red_yellow_rgb <- as.matrix(read.table("z_red_yellow.txt")[,])
red_yellow <- apply(red_yellow_rgb/255, 1, function(x) rgb(x[1], x[2], x[3]))
n <- length(red_yellow)

x11(width=12, height=3)
png(file.path(outdir, "colorbar_red_yellow.png"), width=1200, height=300)
image(1:n, 1, as.matrix(1:n), col = red_yellow, 
        xlab = "", ylab = "", xaxt = "n", yaxt = "n", 
        bty = "n")
dev.off(); dev.off()
