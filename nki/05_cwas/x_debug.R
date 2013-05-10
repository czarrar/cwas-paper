#!/usr/bin/env Rscript

library(connectir)

load("debug.rda")
subs.cormaps <- lapply(1:ncol(mat.subs.cormaps), function(i) as.big.matrix(t(mat.subs.cormaps[,i,drop=F])))
seedCorMaps <- big.matrix(nvoxs-1, nsubs, type=type, shared=FALSE)

i <- 1
.Call("subdist_combine_submaps", subs.cormaps, as.double(i), 
      as.double(voxs[-seeds[i]]), seedCorMaps, PACKAGE="connectir")

dmats <- big.matrix(nsubs^2, 1, type="double", shared=parallel)
.subdist_distance(seedCorMaps, dmats, dists[i], FALSE, method)

# ###
# # Setup
# ###
# 
# library(inline)
# library(connectir)
# 
# plugin_bigmemory <- function() {     
#    l <- getPlugin("RcppArmadillo")     
#       
#    l$includes <- paste(l$includes, '     
#  #include "bigmemory/BigMatrix.h"     
#  #include "bigmemory/MatrixAccessor.hpp"     
#  #include "bigmemory/bigmemoryDefines.h"     
#  #include "bigmemory/isna.hpp"     
#     ')     
#     
#     l$LinkingTo <- c("bigmemory", l$LinkingTo)     
#       
#     l$Depends <- c("bigmemory", l$Depends)     
#       
#     return(l)     
# } 
# registerPlugin("bigmemory", plugin_bigmemory)     
# 
# plugin_connectir <- function() {     
#    l <- getPlugin("bigmemory")     
#       
#    l$includes <- paste(l$includes, '     
#  #include "connectir/connectir.h"     
#     ')     
#     
#     l$LinkingTo <- c("connectir", l$LinkingTo)     
#       
#     l$Depends <- c("connectir", l$Depends)     
#       
#     return(l)     
# } 
# registerPlugin("connectir", plugin_connectir)     
# 
# 
# ###
# # Inline C Code
# ###
# 
# test_subdist_combine_submaps <- cxxfunction( signature(Slist_corMaps='List', 
#                                                        Sseed='numeric', 
#                                                        SvoxInds='numeric', 
#                                                        SseedCorMaps='object'), 
# '
#     try {        
#         // Setup Inputs
#         printf("Setting up\\n");
#         Rcpp::List list_corMaps(Slist_corMaps);
#         index_type seed = static_cast<index_type>(DOUBLE_DATA(Sseed)[0] - 1);
#         Rcpp::NumericVector voxInds(SvoxInds);
#         index_type nsubs = static_cast<index_type>(list_corMaps.size());
#         index_type nvoxs = static_cast<index_type>(voxInds.size());
#         //arma::mat seedCorMaps(1,1); const double* old_mptr = seedCorMaps.memptr();
#         //sbm_to_arma_xd(SseedCorMaps, seedCorMaps); double* seedMap;
#         BM_TO_ARMA_ONCE(SseedCorMaps, seedCorMaps)
#         double* seedMap;
#         
#         BM_TO_ARMA_ONCE(SseedCorMaps, seedCorMaps)
#         
#         // Copy over subject connectivity maps from list to matrix
#         // and scale
#         printf("Copying over\\n");
#         SEXP SsubCorMaps; 
#         arma::mat subCorMaps(1,1); const double* old_sptr = subCorMaps.memptr();
#         index_type voxi, sub, vox;
#         ////for (sub = 0; sub < nsubs; ++sub)
#         ////{
#         ////    printf("subject: #%i\\n", static_cast<int>(sub+1));
#         ////    PROTECT(SsubCorMaps = VECTOR_ELT(Slist_corMaps, sub));
#         ////    sbm_to_arma_xd(SsubCorMaps, subCorMaps);
#         ////    UNPROTECT(1);
#         ////    
#         ////    seedMap = const_cast<double *>(seedCorMaps.colptr(sub));
#         ////    printf("...going through voxels\\n");
#         ////    for (voxi=0; voxi < nvoxs; ++voxi) {
#         ////        vox = static_cast<index_type>(voxInds(voxi)-1);
#         ////        seedMap[voxi] = subCorMaps(seed,vox);
#         ////    }
#         ////}
#         //
#         //printf("freeing up memory\\n");
#         //seedMap = NULL;
#         //free_arma(seedCorMaps, old_mptr);
#         //free_arma(subCorMaps, old_sptr);
#         //
#         //return SseedCorMaps;
#     } catch(std::exception &ex) {
#         forward_exception_to_r(ex);
#     } catch(...) {
#         ::Rf_error("c++ exception (unknown reason)");
#     }
#     
#     return R_NilValue;
# ', plugin = "connectir")

detach("package:connectir", unload = TRUE)
library.dynam.unload("connectir", system.file(package = "connectir"))
library(connectir)
