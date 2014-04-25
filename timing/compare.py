#!/usr/bin/env python

"""
Here we compare the timing of different 
"""

import sys
sys.path.insert(0, '/home2/data/Projects/CPAC_Regression_Test/nipype-installs/fcp-indi-nipype/running-install/lib/python2.7/site-packages')
sys.path.insert(1, "/home2/data/Projects/CPAC_Regression_Test/2013-05-30_cwas/C-PAC")
sys.path.append("/home/data/PublicProgram/epd-7.2-2-rh5-x86_64/lib/python2.7/site-packages")
#sys.path.insert(0, "/Users/zarrar/Dropbox/Code/C-PAC")

import time
import multiprocessing
import numpy as np
from sklearn.metrics.pairwise import euclidean_distances

from sklearn import svm
from sklearn.cluster import MiniBatchKMeans, KMeans

from mdmr import *
#from CPAC.cwas.mdmr import gower_center_many, ftest_fast
#from CPAC.cwas.hatify import gen_h, gen_h2


def gen_data(nsubs=100, nrois=800, nvoxs=10, effect_size=0.1):
    """
    Creates the correlation maps across subjects
    """
    grp         = np.repeat([0,1], nsubs/2)
    design      = np.vstack((np.ones(nsubs), grp)).T
    
    # Get it to be between -1 and 1 (correlation matrix)
    r           = 1 - effect_size
    cmats       = (r - -r) * np.random.random((nvoxs, nrois, nsubs)) + -r
    
    # Add the group effects to 10% of ROIs
    for i in xrange(nvoxs):
        select_rois = np.repeat([0,1], [nrois-np.floor(nrois*0.1), np.floor(nrois*0.1)])
        np.random.shuffle(select_rois)    
        for j in (grp==1).nonzero()[0]:
            cmats[i,select_rois==1,j] += effect_size
    
    return cmats, design, grp


def local_degree(cmats, design, thresh=0.2):
    from scipy import stats
    
    degree  = np.sum(cmats>thresh, axis=1)
    
    inv_xx  = np.linalg.inv(design.T.dot(design))
    B       = inv_xx.dot(design.T).dot(degree.T)
    
    nobs    = design.shape[0]                       # number of observations
    ncoef   = design.shape[1]                       # number of coef.
    df_e    = nobs - ncoef                          # degrees of freedom, error 
    df_r    = ncoef - 1                             # degrees of freedom, regression 

    e       = degree.T - np.dot(design, B)          # residuals
    
    mse     = np.sum(e**2, axis=0)/df_e
    dd      = np.diagonal(inv_xx)
    
    con     = np.array([0,1])
    coef    = np.dot(con, B)
    c_dd    = np.dot(con, dd)
    se      = np.dot(mse, c_dd)
    tvals   = coef/se
    ps      = stats.t.sf(np.abs(tvals), df_e) * 2  # coef. p-values
    
    return ps


def local_glm(cmats, design):
    # k^3 + k^2*n + k^2*n + k*n*v
    from scipy import stats
    
    nvoxs   = cmats.shape[0]
    nsig    = np.zeros(nvoxs)
    
    for i in xrange(nvoxs):
        inv_xx  = np.linalg.inv(design.T.dot(design))
        B       = inv_xx.dot(design.T).dot(cmats[i].T)
        
        nobs    = cmats.shape[2]                        # number of observations
        ncoef   = design.shape[1]                       # number of coef.
        df_e    = nobs - ncoef                          # degrees of freedom, error 
        df_r    = ncoef - 1                             # degrees of freedom, regression 
        
        e       = cmats[i].T - np.dot(design, B)        # residuals
        
        mse     = np.sum(e**2, axis=0)/df_e
        dd      = np.diagonal(inv_xx)
    
        con     = np.array([0,1])
        coef    = np.dot(con, B)
        c_dd    = np.dot(con, dd)
        se      = np.dot(mse, c_dd)
        tvals   = coef/se
        ps      = stats.t.sf(np.abs(tvals), df_e) * 2  # coef. p-values
        
        nsig[i] = (ps<0.05).sum()
    
    #self.R2 = 1 - self.e.var()/self.y.var()         # model R-squared
    #self.R2adj = 1-(1-self.R2)*((self.nobs-1)/(self.nobs-self.ncoef))   # adjusted R-square

    #self.F = (self.R2/self.df_r) / ((1-self.R2)/self.df_e)  # model F-statistic
    #self.Fpv = 1-stats.f.cdf(self.F, self.df_r, self.df_e)  # F-statistic p-value
    
    return nsig


def local_mdmr(cmats, design):
    """
    Computes MDMR but without any permutations so only returns an F-value.
    
    Parameters
    ----------
    cmats : numpy.ndarray
        A matrix of `nvoxs` `nrois` x `nobs` representing a correlation map for each 
        observation, which typically is a roi/voxel in one participant's brain.
    design : numpy.ndarray
        A matrix of `nobs` x `nregressors`. We assume that the first column is 
        the intercept with all 1s and the second column is of interest.
    """
    
    cols    = [1]   # assume only one regressor
    nobs    = design.shape[0]
    nvoxs   = cmats.shape[0]
    
    dmats   = np.zeros((nvoxs,nobs,nobs))
    for i in xrange(nvoxs):
        dmats[i] = euclidean_distances(cmats[i].T)
    
    Gs      = gower_center_many(dmats)
    
    df_among = len(cols)
    df_resid = nobs - design.shape[1]
    df_total = nobs - 1

    H2      = gen_h2(design, cols).flatten()
    IH      = (np.eye(nobs,nobs) - gen_h(design, cols)).flatten()

    F_perms = ftest_fast(H2, IH, Gs, df_among, df_resid)
    
    return F_perms


def local_svm(cmats, grp):
    """
    Computes SVM with a linear kernel. Returns the prediction accuracy of the 
    model (I know not ideal).
    
    Parameters
    ----------
    cmats : numpy.ndarray
        A matrix of `nvoxs` x `nrois` x `nobs` representing a correlation map for each 
        observation, which typically is a roi/voxel in one participant's brain.
    grp : numpy.ndarray
        A vector of `nobs` with the group membership (i.e. labels for prediction).
    """
    nvoxs       = cmats.shape[0]
    predaccu    = np.zeros(nvoxs)
    
    for i in xrange(nvoxs):
        clf         = svm.SVC(kernel='linear')
        clf.fit(cmats[i].T, grp)
        pred        = clf.predict(cmats[i].T)
        predaccu[i] = np.sum(pred == grp)/float(pred.size)
        
    return predaccu


def local_kmeans(cmats, grp):
    nvoxs       = cmats.shape[0]
    predaccu    = np.zeros(nvoxs)
    
    for i in xrange(nvoxs):
        k_means     = KMeans(init='k-means++', k=2, n_init=10)
        k_means.fit(cmats[i].T)
        pred        = k_means.labels_
        predaccu[i] = np.sum(pred == grp)/float(pred.size)
    
    return predaccu

def time_fun(fun, *args):
    niters=20
    etimes = np.zeros(niters)
    for i in xrange(niters):
        start   = time.clock()
        fun(*args)
        end     = time.clock()
        elapsed = end - start
        etimes[i] = elapsed
    return etimes

def run_all(nsubs, nrois, nthreads=2):
    import mkl
    mkl.set_num_threads(nthreads)
    
    print "setup"
    cmats, design, grp = gen_data(nsubs=nsubs, nrois=nrois, nvoxs=nrois)
    
    print "degree"
    dall = time_fun(local_degree, cmats, design)
    
    print "glm"
    gall = time_fun(local_glm, cmats, design)
    
    print "mdmr"
    mall = time_fun(local_mdmr, cmats, design)
    
    print "svm"
    sall = time_fun(local_svm, cmats, grp)
    
    print "kmeans"
    kall = time_fun(local_kmeans, cmats, grp)
    
    print "end"
    times = np.vstack((dall, gall, mall, sall, kall))
    
    return times

if __name__ == "__main__":
    # Get the correlations maps, design matrix, and group indices
cmats, design, grp = gen_data(nsubs=100, nrois=1000, nvoxs=1000)

# Comparison
times   = run_all(nsubs=100, nrois=1000, nthreads=8)



def seq_multiples(init, by, len_out):
    seq = np.zeros(len_out)
    seq[0] = init
    for i in xrange(1,len_out):
        seq[i] = seq[i-1] * by
    return seq

def run_all_wrap(args):
    return run_all(*args)

subs    = seq_multiples(10, 2, 7)
rois    = seq_multiples(50, 2, 7)
args    = [ (int(s),int(r)) for r in rois for s in subs ]

p       = multiprocessing.Pool(processes=12)
res     = p.map(run_all_wrap, args)


# nsubs x nrois x niters
time_mat = np.zeros((7,7,10))

