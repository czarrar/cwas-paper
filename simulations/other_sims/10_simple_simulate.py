#!/usr/bin/env python

import sys
#sys.path.append("/Users/zarrar/Dropbox/Code/C-PAC/CPAC/cwas")
sys.path.insert(0, "/home2/data/Projects/CPAC_Regression_Test/2013-05-30_cwas/C-PAC/CPAC/cwas")
sys.path.append("/home/data/PublicProgram/epd-7.2-2-rh5-x86_64/lib/python2.7/site-packages")

import multiprocessing
import numpy as np
from subdist import compute_distances
from sklearn.metrics.pairwise import euclidean_distances
from mdmr import mdmr

# Simulate Group Effect
def dtest(pos_nodes=0, effect=0.0, dist="euclidean", n=100, nodes=400, nperms=4999, iters=100):
    import mkl
    mkl.set_num_threads(2)
    
    print "Start"

    #print "Categorical Effect"
    grp  = np.repeat([0, 1], n/2)
    np.random.shuffle(grp)

    #print "Design Matrix"
    design = np.vstack((np.ones(n), grp)).T
    cols = [1]

    #print "Distance Matrices"
    dmats = np.zeros((iters,n,n))
    for i in xrange(iters):
        #if (i % 10) == 0:
        #    print i,
        # Data
        ## Fist, I created the matrix with the random data
        points = np.random.standard_normal((n,nodes))
        ## Second, I select a random selection of nodes to add the effect
        neg_nodes = nodes - pos_nodes
        change_nodes = np.repeat([0,1], [neg_nodes, pos_nodes])
        np.random.shuffle(change_nodes)
        ## Finally, I add the effect to a select subjects and nodes
        for i in (change_nodes==1).nonzero()[0]:
            points[grp==1,i] += effect
        
        # Compute Distances
        if dist == "euclidean":
            dmat    = euclidean_distances(points)
        elif dist == "pearson":
            dmat    = compute_distances(points)
        else:
            raise Exception("Unknown distance measure %s" % dist)
        dmats[i]    = dmat
    #print ""

    #print "MDMR"
    pvals = []; Fvals = [];
    pvals, Fvals, _, _ = mdmr(dmats, design, cols, nperms)
    
    #print "Done"
    return pvals, Fvals



n     = 100
nodes = 400
ns = np.linspace(0,1,11) * nodes
es = np.linspace(0.0,1.0,11)

def dtest_wrap(args):
    return dtest(*args)

# Get with covariate
p       = multiprocessing.Pool(processes=8)
args    = [ (int(n),e) for n in ns for e in es ]
res     = p.map(dtest_wrap, args)

df_dict = {'nodes': [], 'effect': [], 'power': [], 'fstat': []}
for i,a in enumerate(args):
    print i, a
    
    # Setup
    pos_nodes, effect = a
    prop_nodes   = float(pos_nodes)/nodes # proportion of signif nodes
    pvals, Fvals = res[i]
    
    # Get what you want for this iteration
    power  = np.mean(pvals < 0.05)
    fstat  = Fvals.mean()
    
    # Save
    df_dict['nodes'].append(prop_nodes)
    df_dict['effect'].append(effect)
    df_dict['power'].append(power)
    df_dict['fstat'].append(fstat)

from pandas import DataFrame
df = DataFrame(df_dict, columns=['nodes', 'effect', 'power', 'fstat'])




# Save results to arrays
pvals1  = np.zeros((2, len(ds), len(rs), iters))
fvals1  = np.zeros((2, len(ds), len(rs), iters))

dict_count = {}
for i,a in enumerate(args):
    d = a[1]; di = (ds==d).nonzero()[0][0]
    r = a[2]; ri = (rs==r).nonzero()[0][0]
    
    dict_count.setdefault((d,r), 0)
    dict_count[(d,r)] += 1
    ii = dict_count[(d,r)] - 1
    
    print "d: %s, r: %s, iter: %i" % (d,r,ii+1)
    
    pvals1[:,di,ri,ii] = res[i][0]
    fvals1[:,di,ri,ii] = res[i][1]

lvals1 = np.abs(-np.log10(pvals1))

# Get without covariate
p       = multiprocessing.Pool(processes=12)
args    = [ (n,d,r) for r in rs for d in ds for i in xrange(iters) ]
res     = p.map(dtest_wrap_nocov, args)

# Save results to arrays
pvals2  = np.zeros((len(ds), len(rs), iters))
fvals2  = np.zeros((len(ds), len(rs), iters))

dict_count = {}
for i,a in enumerate(args):
    d = a[1]; di = (ds==d).nonzero()[0][0]
    r = a[2]; ri = (rs==r).nonzero()[0][0]
    
    dict_count.setdefault((d,r), 0)
    dict_count[(d,r)] += 1
    ii = dict_count[(d,r)] - 1
    
    print "d: %s, r: %s, iter: %i" % (d,r,ii+1)
    
    pvals2[di,ri,ii] = res[i][0][0]
    fvals2[di,ri,ii] = res[i][1][0]

lvals2 = np.abs(-np.log10(pvals2))

# Let's save these matrices?
# We want to plot the change over time.


# Summarize
ave_lvals1 = lvals1.mean(axis=3)
ave_fvals1 = fvals1.mean(axis=3)
ave_lvals2 = lvals2.mean(axis=2)
ave_fvals2 = fvals2.mean(axis=2)
power1     = (pvals1<0.05).mean(axis=3)
power2     = (pvals2<0.05).mean(axis=3)

# Save so I can plot in R
from rpy2.robjects import r
from rpy2.robjects.numpy2ri import numpy2ri

r_ds         = numpy2ri(ds); r.assign("ds", r_ds)
r_rs         = numpy2ri(rs); r.assign("rs", r_rs)
r_ave_lvals1 = numpy2ri(ave_lvals1); r.assign("logp.cov1", r_ave_lvals1)
r_ave_fvals1 = numpy2ri(ave_fvals1); r.assign("fstat.cov1", r_ave_fvals1)
r_ave_lvals2 = numpy2ri(ave_lvals2); r.assign("logp.cov0", r_ave_lvals2)
r_ave_fvals2 = numpy2ri(ave_fvals2); r.assign("fstat.cov0", r_ave_fvals2)
r_power1     = numpy2ri(power1); r.assign("power1", r_power1)
r_power2     = numpy2ri(power2); r.assign("power2", r_power2)

r("save(ds, rs, logp.cov1, fstat.cov1, logp.cov0, fstat.cov0, power1, power2, file='summary_vals.rda', compress=TRUE)")
