capitalize <- function(s) {
    paste(
        toupper(substring(s, 1, 1)), 
        substring(s, 2), 
        sep=""
    )    
}

titalize <- function(x) {
    sapply(x, function(xx) {
        s <- strsplit(xx, " ")[[1]]
        paste(toupper(substring(s, 1,1)), substring(s, 2),
            sep="", collapse=" ")
    })
}
