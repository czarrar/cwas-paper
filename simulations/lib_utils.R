zdist <- function(mat, method="cor") {
    switch(method, 
        cor = 1 - corr(mat)
        stop("Unsupported method for zdist")
    )
}
