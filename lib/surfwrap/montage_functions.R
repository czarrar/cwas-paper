surfer_montage_coords <- function(images, nrows=1, ncols=4, 
                                  scalings=rep(1,nrows*ncols), 
                                  row.gap=0, col.gap=0) {
    # Check number of images
    n <- nrows*ncols
    if (length(images) != n)
        stop("# of images is not same as layout rows/cols")
    
    
    ## Get Coordinates
    
    # The montage will have multiple elements (for now 4)
    # and we will refer to each element as a tile    
    
    # Want to scale the images to be roughly the same size
    #images.areas <- sapply(images, function(x) prod(dim(x)[1:2]))
    #images.areas <- sapply(images, function(img) sum(apply(img, c(1,2), sum)!=3))
    #scalings <- min(images.areas)/images.areas
    #scalings <- sqrt(scalings)
    
    # Image dimensions
    images.dims <- sapply(images, dim)
    images.dims <- images.dims[1:2,] * rbind(scalings, scalings)
    images.rows <- matrix(images.dims[1,], nrows, ncols)
    images.cols <- matrix(images.dims[2,], nrows, ncols)
    
    # Row size for each tile
    max.rows <- apply(images.rows, 2, max)
    tile.rows <- images.rows
    for (i in 1:nrow(tile.rows))
        tile.rows[i,] <- max.rows
    
    # Column size for each tile
    max.cols <- apply(images.cols, 1, max)
    tile.cols <- images.cols
    for (i in 1:ncol(tile.cols))
        tile.cols[,i] <- max.cols
    # For each tile, the left-most x coordinate
    tile.xleft <- tile.rows
    tile.xleft[,-1] <- tile.xleft[,-ncols]
    tile.xleft[,1] <- 0
    if (ncol(tile.xleft) > 1) {
        for (i in ncol(tile.xleft):2) {
            tile.xleft[,i] <- rowSums(tile.xleft[,1:i,drop=F])
        }
    }
    ## gaps
    gaps <- seq(col.gap, length=ncols-1, by=col.gap)
    for (i in 1:nrows)
        tile.xleft[i,-1] <- tile.xleft[i,-1] + gaps 
    
    # For each tile, the bottom-most y coordinate
    tile.ybottom <- tile.cols
    tile.ybottom[-nrows,] <- tile.ybottom[-1,]
    tile.ybottom[nrows,] <- 0
    for (i in (nrows-1):1)
        tile.ybottom[i,] <- colSums(tile.ybottom[i:nrows,,drop=F])
    # gaps
    gaps <- rev(seq(row.gap, length=nrows-1, by=row.gap))
    for (i in 1:ncols)
        tile.ybottom[-nrows,i] <- tile.ybottom[-nrows,i] + gaps 
    
    # For each image, the left and right x coordinates
    images.xleft <- (tile.rows - images.rows)/2 + tile.xleft
    images.xright <- images.xleft + images.rows
    
    # For each image, the bottom and top y coordinates
    images.ybottom <- (tile.cols - images.cols)/2 + tile.ybottom
    images.ytop <- images.ybottom + images.cols
    
    # width/height in pixels
    width.pixels <- sum(max.rows) + col.gap*(ncols-1)
    height.pixels <- sum(max.cols) + row.gap*(nrows-1)
    
    # width/heigh in regular numbers (essentially flip stuff)
    width.image <- sum(apply(images.cols, 2, max)) + col.gap*(ncols-1)
    height.image <- sum(apply(images.rows, 1, max)) + row.gap*(nrows-1)
    
    return(list(
        xleft = images.xleft, 
        ybottom = images.ybottom, 
        xright = images.xright, 
        ytop = images.ytop, 
        width = width.pixels, 
        height = height.pixels, 
        fig.width = width.image, 
        fig.height = height.image
    ))
}

surfer_montage_dims <- function(coords) {
    m <- max(coords$fig.width, coords$fig.height)
    return(list(
        width = (coords$fig.width/m)*10, 
        height = (coords$fig.height/m)*10
    ))
}

surfer_montage_viz <-  function(images, coords, hemi.labels=F) {    
    ## Plot
    
    n <- length(images)
        
    # setup the plot
    #plot.new()
    par(family="Helvetica")
    par(mar=c(0,0,0,0), oma=c(0,0,0,0)) ## no margins
    #plot.window(c(0,width.pixels),c(0,height.pixels))
    plot(c(0,coords$width), c(0,coords$height), type = "n", 
         xlab="", ylab="", frame.plot=FALSE, xaxt='n', yaxt='n', 
         xaxs="i", yaxs="i")
    
    # viz the images
    for (i in 1:n) {
        rasterImage(images[[i]], coords$xleft[i], coords$ybottom[i], 
                    coords$xright[i], coords$ytop[i])
    }
    
    if (hemi.labels) {
        # add hemisphere labels
        text(round(coords$width*0.05), round(coords$height*0.5), "L", cex=2.4)
        text(coords$width-round(coords$width*0.05), round(coords$height*0.5), 
             "R", cex=2.4)
    }
    
    return(NULL)
}
