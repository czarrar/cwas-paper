#!/usr/bin/env python

import sys
#sys.path.append("/Users/zarrar/Dropbox/Code/C-PAC/CPAC/cwas")
sys.path.insert(0, "/home2/data/Projects/CPAC_Regression_Test/2013-05-30_cwas/C-PAC/CPAC/cwas")
sys.path.append("/home/data/PublicProgram/epd-7.2-2-rh5-x86_64/lib/python2.7/site-packages")

import multiprocessing
import numpy as np
from mdmr import mdmr
from sklearn.metrics.pairwise import euclidean_distances


# Simulate
def dtest(n=50, d=0.0, r=0.0, model_covariate=True, niters=100, nperms=4999):
    import mkl
    mkl.set_num_threads(2)
    
    d   = float(d)
    r   = float(r)
        
    # Data/Distances
    pvals = np.zeros(niters)
    Fvals = np.zeros(niters)
    for i in xrange(niters):
        # Design
        
        ## Categorical
        gp  = np.repeat([0, 1], n/2)
        np.random.shuffle(gp)
        x   = gp*d + np.random.standard_normal(n)
        
        ## Continuous
        # see http://stackoverflow.com/questions/16024677/generate-correlated-data-in-python-3-3
        # and http://stats.stackexchange.com/questions/19367/creating-two-random-sequences-with-50-correlation?lq=1
        uncorrelated    = np.random.standard_normal((2,n))
        motion          = uncorrelated[0]
        y               = r*motion + np.sqrt(1-r**2)*uncorrelated[1]
        
        ## Design Matrix
        if model_covariate:
            design = np.vstack((np.ones(n), gp, motion)).T
        else:
            design = np.vstack((np.ones(n), gp)).T
                
        # Date
        points = np.vstack((x,y)).T
        
        # Distances
        dmat  = euclidean_distances(points)
        dmats = dmat[np.newaxis,:,:]
        
        # Only the group effect is the variable of interest
        cols = [1]
        
        # Call MDMR
        pval, Fval, _, _ = mdmr(dmats, design, cols, nperms)
        
        pvals[i] = pval
        Fvals[i] = Fval
    
    return pvals, Fvals


# We just need to run the above
# for a given n and nperms
# and varying d (effect of interest)
# and varying r but only 3 times (covariate)
# and we model or don't model r (the covariate)

n  = 50
ds = np.linspace(0,1.5,16)
rs = np.linspace(0,1,3)
niters = 1000
nperms = 999

def dtest_wrap(args):
    return dtest(*args, niters=niters, nperms=nperms)

def dtest_wrap_nocov(args):
    return dtest(*args, model_covariate=False, niters=niters, nperms=nperms)

# Get with covariate
p       = multiprocessing.Pool(processes=12)
args    = [ (n,d,r) for r in rs for d in ds ]
res1    = p.map(dtest_wrap, args)

# Get without covariate
p       = multiprocessing.Pool(processes=12)
args    = [ (n,d,r) for r in rs for d in ds ]
res2    = p.map(dtest_wrap_nocov, args)


pmat = np.zeros((2,len(ds),len(rs),niters))
fmat = np.zeros((2,len(ds),len(rs),niters))
for cov in [0,1]:
    if cov == 0:
        res = res2
    elif cov == 1:
        res = res1
        
    for i,a in enumerate(args):
        d = a[1]; di = (ds==d).nonzero()[0][0]
        r = a[2]; ri = (rs==r).nonzero()[0][0]
        
        pvals, Fvals        = res[i]
        pmat[cov,di,ri,:]   = pvals
        fmat[cov,di,ri,:]   = Fvals


# Save so I can plot in R
from rpy2.robjects import r
from rpy2.robjects.numpy2ri import numpy2ri

r_ds = numpy2ri(ds); r.assign("ds", r_ds)
r_rs = numpy2ri(rs); r.assign("rs", r_rs)

r_pmat = numpy2ri(pmat); r.assign("pmat", r_pmat)
r_fmat = numpy2ri(fmat); r.assign("fmat", r_fmat)

r("save(pmat, fmat, file='new_summary_vals.rda', compress=TRUE)")




# # false positive is when you say something is significant but it's really not
# # false negative is when you something is not significant but it really is
# 
# # in this case, 
# # false positive would be when there is no effect but you get some with p < 0.05
# # false negative would be when there is an effect but you don't find it with p < 0.05
# 
# dtest(n)
# 
# 
# 
# 
# 
# es = 0:4 / 4
# nrej = c(5,20,33,38,39)
# ntrial = c(100,40,40,40,40)
# prej = nrej / ntrial
# 
# 
# require(binom)
# bc = binom.confint(nrej,ntrial,methods="exact")
# require(gplots)
# plotCI(es, prej, ui=bc$upper, li=bc$lower, gap=0, type="o", xlab=“Group difference", ylab="Power”, ylim=0:1)
# 
# 
# 
# n  = 100
# ds = np.linspace(0,1,11)
# rs = np.linspace(0,1,11)
# iters = 20
# 
# def dtest_wrap(args):
#     return dtest(*args)
# 
# def dtest_wrap_nocov(args):
#     return dtest(*args, model_covariate=False)
# 
# # Get with covariate
# p       = multiprocessing.Pool(processes=12)
# args    = [ (n,d,r) for r in rs for d in ds for i in xrange(iters) ]
# res     = p.map(dtest_wrap, args)
# 
# # Save results to arrays
# pvals1  = np.zeros((2, len(ds), len(rs), iters))
# fvals1  = np.zeros((2, len(ds), len(rs), iters))
# 
# dict_count = {}
# for i,a in enumerate(args):
#     d = a[1]; di = (ds==d).nonzero()[0][0]
#     r = a[2]; ri = (rs==r).nonzero()[0][0]
#     
#     dict_count.setdefault((d,r), 0)
#     dict_count[(d,r)] += 1
#     ii = dict_count[(d,r)] - 1
#     
#     print "d: %s, r: %s, iter: %i" % (d,r,ii+1)
#     
#     pvals1[:,di,ri,ii] = res[i][0]
#     fvals1[:,di,ri,ii] = res[i][1]
# 
# lvals1 = np.abs(-np.log10(pvals1))
# 
# # Get without covariate
# p       = multiprocessing.Pool(processes=12)
# args    = [ (n,d,r) for r in rs for d in ds for i in xrange(iters) ]
# res     = p.map(dtest_wrap_nocov, args)
# 
# # Save results to arrays
# pvals2  = np.zeros((len(ds), len(rs), iters))
# fvals2  = np.zeros((len(ds), len(rs), iters))
# 
# dict_count = {}
# for i,a in enumerate(args):
#     d = a[1]; di = (ds==d).nonzero()[0][0]
#     r = a[2]; ri = (rs==r).nonzero()[0][0]
#     
#     dict_count.setdefault((d,r), 0)
#     dict_count[(d,r)] += 1
#     ii = dict_count[(d,r)] - 1
#     
#     print "d: %s, r: %s, iter: %i" % (d,r,ii+1)
#     
#     pvals2[di,ri,ii] = res[i][0][0]
#     fvals2[di,ri,ii] = res[i][1][0]
# 
# lvals2 = np.abs(-np.log10(pvals2))
# 
# # Let's save these matrices?
# # We want to plot the change over time.
# 
# 
# # Summarize
# ave_lvals1 = lvals1.mean(axis=3)
# ave_fvals1 = fvals1.mean(axis=3)
# ave_lvals2 = lvals2.mean(axis=2)
# ave_fvals2 = fvals2.mean(axis=2)
# power1     = (pvals1<0.05).mean(axis=3)
# power2     = (pvals2<0.05).mean(axis=3)
# 
# # Save so I can plot in R
# from rpy2.robjects import r
# from rpy2.robjects.numpy2ri import numpy2ri
# 
# r_ds         = numpy2ri(ds); r.assign("ds", r_ds)
# r_rs         = numpy2ri(rs); r.assign("rs", r_rs)
# r_ave_lvals1 = numpy2ri(ave_lvals1); r.assign("logp.cov1", r_ave_lvals1)
# r_ave_fvals1 = numpy2ri(ave_fvals1); r.assign("fstat.cov1", r_ave_fvals1)
# r_ave_lvals2 = numpy2ri(ave_lvals2); r.assign("logp.cov0", r_ave_lvals2)
# r_ave_fvals2 = numpy2ri(ave_fvals2); r.assign("fstat.cov0", r_ave_fvals2)
# r_power1     = numpy2ri(power1); r.assign("power1", r_power1)
# r_power2     = numpy2ri(power2); r.assign("power2", r_power2)
# 
# r("save(ds, rs, logp.cov1, fstat.cov1, logp.cov0, fstat.cov0, power1, power2, file='summary_vals.rda', compress=TRUE)")
