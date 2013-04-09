surfer_montage_coords <- function(images) {
    # Check number of images
    nrows <- 2; ncols <- 2  # TODO: make this dynamic
    n <- nrows*ncols
    if (length(images) != n)
        stop("# of images is not same as layout rows/cols")
    
    
    ## Get Coordinates
    
    # The montage will have multiple elements (for now 4)
    # and we will refer to each element as a tile    
    
    # Image dimensions
    images.dims <- sapply(images, dim)
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
    tile.xleft[,-1] <- tile.xleft[,-ncol(tile.xleft)]
    tile.xleft[,1] <- 0
    for (i in ncol(tile.xleft):2)
        tile.xleft[,i] <- rowSums(tile.xleft[,1:i])

    # For each tile, the bottom-most y coordinate
    tile.ybottom <- tile.cols
    tile.ybottom[-nrow(tile.ybottom),] <- tile.ybottom[-1,]
    tile.ybottom[nrow(tile.ybottom),] <- 0
    for (i in (nrow(tile.ybottom)-1):1)
        tile.ybottom[i,] <- colSums(tile.ybottom[i:nrow(tile.ybottom),])
    
    # For each image, the left and right x coordinates
    images.xleft <- (tile.rows - images.rows)/2 + tile.xleft
    images.xright <- images.xleft + images.rows
    
    # For each image, the bottom and top y coordinates
    images.ybottom <- (tile.cols - images.cols)/2 + tile.ybottom
    images.ytop <- images.ybottom + images.cols
    
    # width/height in pixels
    width.pixels <- sum(max.rows); height.pixels <- sum(max.cols)
    
    return(list(
        xleft = images.xleft, 
        ybottom = images.ybottom, 
        xright = images.xright, 
        ytop = images.ytop, 
        width = width.pixels, 
        height = height.pixels
    ))
}

surfer_montage_dims <- function(coords) {
    m <- max(coords$width, coords$height)
    return(list(
        width = (coords$width/m)*10, 
        height = (coords$height/m)*10
    ))
}

surfer_montage_viz <-  function(images, coords) {    
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
    
    # add hemisphere labels
    text(round(coords$width*0.05), round(coords$height*0.5), "L", cex=2.4)
    text(coords$width-round(coords$width*0.05), round(coords$height*0.5), 
         "R", cex=2.4)
    
    return(NULL)
}
