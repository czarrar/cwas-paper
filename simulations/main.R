library(igraph)
library(plyr)
library(doMC)

source("lib_mdmr.R")
source("lib_utils.R")

# Settings to vary
## subject
many_nsubs <- c(20, 50, 100, 150, 200, 250, 300)
## group differences
many_effect_sizes <- c(0.02, 0.04, 0.06, 0.08, 0.1, 0.15, 0.2, 0.3)
## connections to change per node
many_num_conns_change_per_node <- c(1, seq(2,10,2), 14, 18)
## iterations
niters <- 10

settings <- c()
# Other settings
settings$verbose <- TRUE
## parallel
settings$parallel <- FALSE   # getting segfaults???
settings$nforks <- 3
settings$nthreads <- 4
## graph
settings$nnodes <- 100
settings$nnei <- 12
## group differences
settings$effect_size_noise <- 0.01   # proportion or percentage 1%
settings$num_nodes_change <- nnodes/2
settings$crit.pval <- 0.05

# Set Parallelization
if (settings$parallel)
    set_parallel_procs(settings$nforks, settings$nthreads, settings$verbose)

res <- ldply(1:niters, function(ii) {
    vcat(settings$verbose, "ITERATION: %i", ii)
    
    ###
    # Group Connectivity Matrix
    ###

    source("01_group_mat.R")

    # 1. Generate group adjacency matrix
    group.adj <- create_adjacency_matrix(settings)

    # 2. Add weights
    group.wt <- add_weights_to_matrix(group.adj, settings)
    
    
    res <- ldply(many_nsubs, function(nsubs) {
        vcat(settings$verbose, "# OF SUBJECTS: %i", nsubs)
        
        settings$nsubs <- nsubs
        grp.label <- factor(rep(c("A","B"),each=settings$nsubs/2))
        df <- data.frame(group=grp.label)
        
        ###
        # Subject Connectivity Matrices
        ###

        source("02_subject_mats.R")

        # 3. Generate subject matrices
        subjects.wt <- create_weighted_subject_matrices(group.adj, settings)

        
        res <- mdply(expand.grid(effect_size=many_effect_sizes, num_conns_change=many_num_conns_change_per_node), 
                        function(effect_size, num_conns_change) {
                            vcat(settings$verbose, "EFFECT SIZE: %f", effect_size)
                            vcat(settings$verbose, "# OF CONNECTIONS: %i", num_conns_change)
                            
                            settings$effect_size <- effect_size
                            settings$num_conns_change_per_node <- num_conns_change
                            
                            ###
                            # Add Group Differences
                            ###

                            # can vary effect size and number of connections effected

                            source("03_group_differences.R")

                            # 4. Select nodes to change
                            nodes <- select_nodes(group.adj, settings)

                            # 5. Select connections to change
                            conns <- select_connections(nodes, group.adj, settings)

                            # 6. Add in group differences with a bit of noise
                            subjects.wt <- add_group_differences(subjects.wt, grp.label, conns, settings)


                            ###
                            # Tests
                            ###

                            source("04_tests.R")

                            # Regression (at each connection)
                            res.aov <- anova_performance(subjects.wt, df, conns, settings)

                            # Degree and then regression
                            res.degree <- degree_centrality_performance(subjects.wt, df, nodes, settings)

                            # Distances & K-Means & MDMR
                            distances <- compute_distances(subjects.wt, settings)
                            res.mdmr <- mdmr_performance(distances, df, nodes, settings)
                            
                            data.frame(
                                method = c("glm", "degree", "mdmr"), 
                                sensitivity = c(res.aov$sensitivity, res.degree$sensitivity, res$mdmr$sensitivity), 
                                specificity = c(res.aov$specificity, res.degree$specificity, res$mdmr$specificity)
                            )
                        }
            )
        
        res$subjects <- nsubs
        
        res
    })
    
    res$iteration <- ii
    
    res
})

