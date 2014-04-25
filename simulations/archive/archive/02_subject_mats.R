create_weighted_subject_matrices <- function(group.wt, settings) {    
    vcat(settings$verbose, "Generating %i weighted subject matrices", settings$nsubs)
    
    # each subject is a random variation on the group average
    subjects.wt <- aaply(group.wt, c(1,2), function(x) {
        variation <- constrain_rnorm(settings$nsubs, 0, 0.1, min=-0.2, max=0.2)
        x + variation        
    }, .progress="text", .parallel=settings$parallel)
    
    names(dim(subjects.wt)) <- c("node", "node", "subject")
    dimnames(subjects.wt) <- list(node=1:nrow(group.wt), node=1:ncol(group.wt), subject=1:settings$nsubs)
    
    subjects.wt
}

