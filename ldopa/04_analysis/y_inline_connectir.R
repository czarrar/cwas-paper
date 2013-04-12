library(inline)
library(connectir)

plugin_bigmemory <- function() {     
   l <- getPlugin("RcppArmadillo")     
      
   l$includes <- paste(l$includes, '     
 #include "bigmemory/BigMatrix.h"     
 #include "bigmemory/MatrixAccessor.hpp"     
 #include "bigmemory/bigmemoryDefines.h"     
 #include "bigmemory/isna.hpp"     
    ')     
    
    l$LinkingTo <- c("bigmemory", l$LinkingTo)     
      
    l$Depends <- c("bigmemory", l$Depends)     
      
    return(l)     
} 
registerPlugin("bigmemory", plugin_bigmemory)     

plugin_connectir <- function() {     
   l <- getPlugin("bigmemory")     
      
   l$includes <- paste(l$includes, '     
 #include "connectir/connectir.h"     
    ')     
    
    l$LinkingTo <- c("connectir", l$LinkingTo)     
      
    l$Depends <- c("connectir", l$Depends)     
      
    return(l)     
} 
registerPlugin("connectir", plugin_connectir)     


# Convert roi-level data to be voxelwise
rois_to_voxelwise <- cxxfunction( signature(sA = "object", sRow = "numeric", sRoiInds='List', sNvoxs = "numeric"), 
' 
  try{
    BM_TO_ARMA_ONCE(sA, A)
    double row = DOUBLE_DATA(sRow)[0] - 1;
    Rcpp::List list_roi_inds(sRoiInds);
    double nvoxs = DOUBLE_DATA(sNvoxs)[0];
    
    arma::vec voxs(nvoxs);
    for (size_t i = 0; i < A.n_cols; ++i) {
        SEXP s_roi_inds = list_roi_inds[i];
        Rcpp::NumericVector roi_inds(s_roi_inds);
        int ninds = roi_inds.size();
        for (int j = 0; j < ninds; ++j)
            voxs[roi_inds[j]-1] = A(row,i);
    }
    
    return Rcpp::wrap( voxs );
  } catch( std::exception &ex ) {
    forward_exception_to_r( ex );
  } catch(...) { 
    ::Rf_error( "c++ exception (unknown reason)" ); 
  }
  return R_NilValue; // -Wall
', plugin = "connectir")



# Cluster Table
cluster_table_src = '
using namespace arma;

vec all_inds = Rcpp::as<vec>(R_all_inds);
vec voxs_to_use = Rcpp::as<vec>(R_voxs_to_use);
vec clust_vals = Rcpp::as<vec>(R_clust_vals);
vec raw_vals = Rcpp::as<vec>(R_raw_vals);
vec offset_inds = Rcpp::as<vec>(R_offset_inds);
Rcpp::NumericVector C_last_ind(R_last_ind);
double last_ind = C_last_ind[0];

double clust_i, clust_num, clust_size, clust_mass = 0;
int c_ind, ind;

size_t n_voxs = all_inds.n_elem;
size_t n_inds = offset_inds.n_elem;
vec nei_inds(n_inds);
mat center_inds(0,1);

mat sizes(0,1); mat masses(0,1);

for(size_t i = 0; i < n_voxs; ++i)
{
    c_ind = all_inds(i);
    // TODO: check to see if this will work?
    if (voxs_to_use(c_ind) == 0) continue;
    
    // One less voxel
    voxs_to_use(c_ind) = 0;
    
    // Initialize number, size, and mass
    clust_num = clust_num + 1;
    clust_size = 1;
    clust_mass = raw_vals(c_ind);
    
    // Save center index
    center_inds.insert_rows(0, 1, false);
    center_inds(0,0) = c_ind;
    
    // Update cluster voxel val
    clust_vals(c_ind) = clust_num;
    
    while (center_inds.n_elem > 0) 
    {
        // Get neighbors
        c_ind = center_inds(0);
        nei_inds = c_ind + offset_inds;
    
        // Loop through each neighbor
        for(size_t j = 0; j < n_inds; ++j)
        {
            ind = nei_inds(j);
    
            // TODO: test speed improvement with [i]
            if (ind > 0 && ind < last_ind) {
                if (voxs_to_use(ind) == 1)
                {
                    // Save index to later look at its neighors
                    center_inds.insert_rows(1, 1, false);
                    center_inds(1,0) = ind;
            
                    // One less voxel
                    voxs_to_use(ind) = 0;
                
                    // Update size, mass, and cluster voxel val
                    clust_size = clust_size + 1;
                    clust_mass = clust_mass + raw_vals(ind);
                    clust_vals(ind) = clust_num;
                }
            }
        }

        // Get rid of the center ind that started this
        center_inds.shed_row(0);
    }
    
    clust_i = clust_num - 1;
    
    sizes.insert_rows(clust_i, 1, false);
    masses.insert_rows(clust_i, 1, false);
    
    sizes(clust_i,0) = clust_size;
    masses(clust_i,0) = clust_mass;
    
}

return Rcpp::List::create(Rcpp::Named("n") = Rcpp::wrap( clust_num ),
                          Rcpp::Named("sizes") = Rcpp::wrap( sizes ),
                          Rcpp::Named("masses") = Rcpp::wrap( masses ), 
                          Rcpp::Named("clust") = Rcpp::wrap( clust_vals ));
'


inline_cluster_table <- cxxfunction( 
    signature(R_all_inds = "numeric", R_voxs_to_use = "numeric", 
              R_clust_vals = "numeric", R_raw_vals = "numeric", 
              R_offset_inds = "numeric", R_last_ind = "numeric"), 
    body = cluster_table_src, 
    plugin = "RcppArmadillo"
)

# New cluster table making use of c++ inline function
cpp.cluster.table <- function(x, vox.thr=0, dims=NULL, mask=NULL, 
                              nei=1, nei.dist=3, pad=1) 
{
    # TEMPORARY
    #x <- vox.fstats[,1]; vox.thr <- 1.5; dims <- hdr$dim; nei <- 1; nei.dist <- 3; pad <- 1
    #orig_mask <- mask
    # TEMPORARY
    
    if (is.null(mask))
        mask <- rep(T, length(x))
    if (is.null(dims)) {
        if (length(dim(x)) != 3)
            stop("If dims isn't provided, then x must be a 3D array")
        dims <- dim(x)
    }
    
    nx <- dims[1]; ny <- dims[2]; nz <- dims[3]
    
    # This pads the mask with zero-voxels around the image
    # note that x is only the non-zero voxels in the mask
    if (pad > 0) {
        mask.pad <- array(F, c(nx+pad*2, ny+pad*2, nz+pad*2))
        mask.pad[(pad+1):(pad+nx), (pad+1):(pad+ny), (pad+1):(pad+nz)] <- T
        
        # New dimensions
        nx <- dim(mask.pad)[1]; ny <- dim(mask.pad)[2]; nz <- dim(mask.pad)[3]
        
        # Get new mask
        mask.pad <- as.vector(mask.pad)
        tmp <- rep(F, length(mask.pad))
        tmp[mask.pad] <- mask
        mask <- tmp
        rm(tmp)
    }
    
    # Vector version of the data, mask, and clusters
    xfull <- vector("numeric", nx*ny*nz)
    mfull <- vector("logical", nx*ny*nz)
    cfull <- mfull*0
    
    # Get neighbours to check for clusters
    # default is 27 (face, edge, corner touching)
    nmat <- expand.grid(list(i=-nei:nei, j=-nei:nei, k=-nei:nei))
    voxdists <- rowSums(abs(nmat))
    nmat <- nmat[voxdists<=nei.dist,]
    offset.inds <- nmat$k*nx*ny + nmat$j*nx + nmat$i    # neighbors relative to center node
    rm(nmat, voxdists)  # only keep offset.inds
    
    # Threshold data and save as new mask
    tmp.mask <- x > vox.thr
    nvoxs <- sum(tmp.mask)
    mfull[mask] <- tmp.mask
    xfull[mask][tmp.mask] <- x[tmp.mask]
    rm(tmp.mask)
    
    last.ind <- length(mfull) + 1   # index w/ end of the data
    
    all.inds <- which(mfull)
    
    ct <- inline_cluster_table(all.inds, mfull, cfull, xfull, 
                               offset.inds, as.double(last.ind))
    
    cfull <- ct$clust
    if (pad > 0)
        cfull <- cfull[mask.pad]
    dim(cfull) <- dims
    
    if (length(ct$sizes) == 0) {
        ct$n <- 0
        ct$sizes <- 0
        ct$masses <- 0
    }
    
    list(
        nclust=ct$n, 
        max.size=max(ct$sizes), 
        max.mass=max(ct$masses), 
        size=ct$sizes[,1],
        mass=ct$masses[,1],
        clust=cfull
    )
}
