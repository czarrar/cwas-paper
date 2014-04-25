create_adjacency_matrix <- function(settings) {
    vcat(settings$verbose, "\nGenerating adjacency matrix")
    g <- watts.strogatz.game(1, settings$nnodes, settings$nnei, 0.05)
    g <- simplify(g)   # removes loops and multiple connections
    adj <- get.adjacency(g)
    as.matrix(adj)
}

add_weights_to_matrix <- function(adj, settings) {
    vcat(settings$verbose, "Generating weighted matrix")
    
    wt <- adj
    
    # set weights for connections
    vcat(settings$verbose, "...for connections")
    conns <- which(adj==1)
    wt[conns] <- constrain_rnorm(length(conns), 0.4, 0.1, min=0.2, max=0.6)
    
    # set weights for non-connections
    vcat(settings$verbose, "...for non-connections")
    no_conns <- which(adj==0)
    wt[no_conns] <- constrain_rnorm(length(no_conns), 0, 0.1, min=-0.2, max=0.2)
    
    # make symetrical
    wt[lower.tri(wt)] <- t(wt)[lower.tri(wt)]
    
    # reset diagonal
    diag(wt) <- 1
    
    as.matrix(wt)
}
