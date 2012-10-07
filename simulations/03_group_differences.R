select_nodes <- function(group.adj, settings) {
    vcat(settings$verbose, "Selecting nodes to change")
    
    # select nodes with enough (real) connections
    change_nodes <- which(colSums(group.adj)>settings$num_conns_change_per_node)
    
    # if too many nodes selected, restrict
    if (length(change_nodes) > settings$num_nodes_change)
        change_nodes <- sort(sample(change_nodes, settings$num_nodes_change))
    
    list(
        change=change_nodes, 
        nochange=(1:settings$nnodes)[-change_nodes]
    )
}

# TODO: this will also select the diagonal to be changed need to fix that
select_connections <- function(nodes, group.adj, settings) {
    vcat(settings$verbose, "Selecting connections to change")
    
    change_mat <- matrix(F, settings$nnodes, settings$nnodes)
    change_mat[,nodes$change] <- apply(group.adj[,nodes$change], 2, function(x) {
        inds <- sample(which(x>0), settings$num_conns_change_per_node)
        conns_to_use <- vector("logical", length(x))
        conns_to_use[inds] <- T
        conns_to_use
    })
    
    list(
        change=which(change_mat), 
        nochange=which(!change_mat)
    )
}

add_group_differences <- function(subjects.wt, grp.label, conns, settings) {
    vcat(settings$verbose, "Adding group differences")
    
    for (si in which(grp.label=="A")) {
        x <- subjects.wt[,,si]
        min_noise <- -(settings$effect_size * settings$effect_size_noise)
        max_noise <- settings$effect_size * settings$effect_size_noise
        es_noise <- runif(length(conns$change), min=min_noise, max=max_noise)
        x[conns$change] <- x[conns$change] + settings$effect_size + es_noise
        subjects.wt[,,si] <- x
    }
    
    subjects.wt
}
