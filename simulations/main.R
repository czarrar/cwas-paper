library(igraph)
library(plyr)
library(Rsge)

source("lib_mdmr.R")
source("lib_utils.R")

# Settings to vary
## subject
many_nsubs <- c(20, 50, 100, 150, 200, 250, 300)
#many_nsubs <- c(100)
## group differences
many_effect_sizes <- c(0.02, 0.04, 0.06, 0.08, 0.1, 0.15, 0.2, 0.3)
#many_effect_sizes <- c(0.06, 0.1, 0.15)
## connections to change per node
many_num_conns_change_per_node <- c(1, seq(2,10,2), 14)
#many_num_conns_change_per_node <- c(2, 4)
## iterations
niters <- 10

settings <- c()
# Other settings
settings$verbose <- TRUE
## parallel
settings$parallel <- TRUE   # getting segfaults???
settings$nforks <- 60
settings$nthreads <- 2
## graph
settings$nnodes <- 100
settings$nnei <- 12
## group differences
settings$effect_size_noise <- 0.01   # proportion or percentage 1%
settings$num_nodes_change <- settings$nnodes/2
settings$crit.pval <- 0.05


sge.options(sge.user.options = sprintf("-S /bin/bash -pe mpi %i", settings$nthreads))

# Set Parallelization
#if (settings$parallel)
#    set_parallel_procs(settings$nforks, settings$nthreads, settings$verbose)

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

        
        combos <- expand.grid(
            effect_size=many_effect_sizes, 
            num_conns_change=many_num_conns_change_per_node
        )
        
        res <- sge.parLapply(1:nrow(combos), function(i) {
                            source("lib_mdmr.R")
                            source("lib_utils.R")
                            
                            blas_set_num_threads(settings$nthreads)
                            omp_set_num_threads(settings$nthreads)
                            
                            effect_size <- combos$effect_size[i]
                            num_conns_change <- combos$num_conns_change[i]
                            
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

                            # Distances & MDMR
                            distances <- compute_distances(subjects.wt, settings)
                            res.mdmr <- mdmr_performance(distances, df, nodes, settings)
                            
                            data.frame(
                                effect.size = settings$effect_size, 
                                connections = settings$num_conns_change_per_node, 
                                method = c("glm", "degree", "mdmr"), 
                                sensitivity = c(res.aov$sensitivity, res.degree$sensitivity, res.mdmr$sensitivity), 
                                specificity = c(res.aov$specificity, res.degree$specificity, res.mdmr$specificity)
                            )
                        }, njobs=settings$nforks, trace=TRUE, debug=TRUE, 
                        function.savelist=c("settings", "combos", "subjects.wt", "group.adj", "group.wt", "grp.label", "df"), 
                        packages=c("igraph", "plyr", "blasctl")
            )
        
        res <- ldply(res, function(x) x)
        res <- cbind(subjects=nsubs, res)
        
        res
    })
    
    res <- cbind(iteration=ii, res)
    
    res
})

