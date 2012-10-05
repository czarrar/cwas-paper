library(igraph)
library(plyr)
library(doMC)

source("lib_mdmr.R")
source("lib_utils.R")

# Settings
run_parallel <- TRUE
ncores <- 3
nthreads <- 2
nsubs <- 200
nnodes <- 100
nnei <- 10
effect_sizes <- c(0.02, 0.04, 0.06, 0.08, 0.1, 0.15, 0.2, 0.3)
effect_size_noise <- 0.01   # 1%
num_nodes_change <- nnodes/20
num_conns_change_per_node <- c(1:5, 6, 8, 10, 12, 15)

if (run_parallel) {
    library(doMC)
    registerDoMC(ncores)
    
    if (system("hostname", intern=T) == "rocky") {
        library(blasctl)
        omp_set_num_threads(nthreads)
    }
}

grp <- factor(rep(c("A","B"),each=nsubs/2))



###
# Group Connectivity Matrix
###

# Generate group adjacency matrix
g <- watts.strogatz.game(1, nnodes, nnei, 0.05)
g <- simplify(g)   # removes loops and multiple connections
group.adj <- get.adjacency(g)

# TODO: HERE I DON'T TAKE INTO ACCOUNT THAT THIS IS A UNDIRECTED GRAPH
# Add weights
group.wt <- group.adj
conns <- which(group.adj==1)
no_conns <- which(group.adj==0)
## for connections
group.wt[conns] <- rnorm(length(conns), 0.4, 0.1)
while (TRUE) {
    bad <- group.wt[conns]<0.2 | group.wt[conns]>0.6
    if (sum(bad) == 0)
        break
    group.wt[conns][bad] <- rnorm(sum(bad), 0.4, 0.1)
}
## for non-connections
group.wt[no_conns] <- rnorm(length(no_conns), 0, 0.1)
while (TRUE) {
    bad <- group.wt[no_conns]<(-0.2) | group.wt[no_conns]>0.2
    if (sum(bad) == 0)
        break
    group.wt[no_conns][bad] <- rnorm(sum(bad), 0, 0.1)
}


###
# Subject Connectivity Matrices
###

# each subject is a random variation on the group average
subjects.wt <- laply(1:nsubs, function(i) {
    subject.wt <- group.wt
    subject.wt[conns] <- subject.wt[conns] + runif(length(conns), min=-0.1, max=0.1)
    subject.wt
}, .progress="text", .parallel=F)

# 1. create group difference (i.e., add effect size)
subjects_with_diffs <- laply(effect_sizes, function(es) {

    # 2. create differences for a different number of connections
    laply(num_conns_change_per_node, function(num_conns) {
        # select nodes to change
        nodes <- which(colSums(group.adj)>=num_conns)
        if (length(nodes) > num_nodes_change)
            nodes <- sort(sample(nodes, num_nodes_change))
        
        # select connections to change
        change_mat <- apply(group.adj[,nodes], 2, function(x) {
            inds <- sample(which(x>0), num_conns)
            conns_to_use <- vector("logical", length(x))
            conns_to_use[inds] <- T
            conns_to_use
        })
        change_inds <- which(change_mat)
        
        # c. add in group difference with bit of noise too
        for (si in which(grp=="A")) {
            x <- subjects.wt[si,,]
            es_noise <- runif(length(change_inds), min=0, max=es*effect_size_noise*2)
            x[change_inds] <- x[change_inds] + es + es_noise
            subjects.wt[si,,] <- x
        }
        
        subjects.wt
    })
    
}, .progress="text", .parallel=run_parallel)


###
# Distance Matrices
###

distances_with_diffs <- llply(distances_with_diffs, function(Dss) {
    
    llply(Dss, function(Ds) {
        aaply(Ds) {
            as.vector(zdist(t(xs[,,ni])))
        })
    })
    
    aaply(, 3, function())
    
})