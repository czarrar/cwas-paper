import numpy as np

"""
These are mostly copies of functions in CPAC.
I have copied them here to make the code more internal.
"""

def add_intercept(x):
    """
    Adds an intercept column to the left of the matrix
    
    Paramaters
    ----------
    x : ndarray
        Design matrix (e.g. with 1st column as your intercept)
    
    Returns
    -------
    x : ndarray
    """
    uno = np.ones((x.shape[0],1))   # intercept
    xx  = np.hstack((uno,x))        # design matrix
    return xx

def hatify(x):
    """
    Distance-based hat matrix
    
    Paramaters
    ----------
    x : ndarray
        Design matrix (e.g. with 1st column as your intercept)
    
    Notes
    -----
    This function assumes that the input is not rank-deficient.
    
    Returns
    -------
    H : ndarray
        This will be a `x.shape[0]` by `x.shape[0]` matrix.
    """
    Q1, R1 = np.linalg.qr(x)
    H = Q1.dot(Q1.T)
    return H

def permute_design(x, cols, indexperm):
    """docstring for permute_design"""
    Xj          = x.copy()
    Xp          = np.take(Xj[:,cols], indexperm, axis=0)    
    Xj[:,cols]  = Xp    
    return Xj

# make sure this function doesn't overwrite
# the original x
def gen_h(x, cols=None, indexperm=None):
    """
    Permuted hat matrix
    
    Parameters
    ----------
    x : ndarray
        Design matrix (e.g. with 1st column as your intercept)
    cols : list (optional)
        Columns to be permuted (if `indexperm` is specified)
    indexperm : list (optional)
        Re-ordering (permuting) of rows in `x`
    
    Returns
    -------
    H : ndarray
        This will be a `x.shape[0]` by `x.shape[0]` matrix.
    """
    if indexperm is not None:
        x = permute_design(x, cols, indexperm)
    H = hatify(x)
    return H
    
def gen_h2(x, cols, indexperm=None):
    """
    Permuted regressor-specific hat matrix
    
    Parameters
    ----------
    x : ndarray
        Design matrix (e.g. with 1st column as your intercept)
    cols : list
        Columns to be permuted (if `indexperm` is specified)
    indexperm : list (optional)
        Re-ordering (permuting) of rows in `x`
    
    Returns
    -------
    H2 : ndarray
        This will be a `x.shape[0]` by `x.shape[0]` matrix.
    """
    # H
    H = gen_h(x, cols, indexperm)
    # H2
    # take H and subtract it by everything other than the columns of interest
    other_cols = [ i for i in range(x.shape[1]) if i not in cols ]
    Xj = x[:,other_cols]
    H2 = H - hatify(Xj)
    return H2

def gower_center(yDis):
    n = yDis.shape[0]
    I = np.eye(n,n)
    uno = np.ones((n,1))
    
    A = -0.5*(yDis**2)
    C = I - (1.0/n)*uno.dot(uno.T)
    G = C.dot(A).dot(C)
    
    return G

def gower_center_many(dmats):
    ntests  = dmats.shape[0]
    nobs    = dmats.shape[1]
    Gs      = np.zeros((nobs**2, ntests))
    
    for i in range(ntests):
        Gs[:,i] = gower_center(dmats[i]).flatten()
    
    return Gs

def calc_ssq_fast(Hs, Gs, transpose=True):
    if transpose:
        ssq = Hs.T.dot(Gs)
    else:
        ssq = Hs.dot(Gs)
    return ssq

def ftest_fast(Hs, IHs, Gs, df_among, df_resid, **ssq_kwrds):
    SS_among = calc_ssq_fast(Hs, Gs, **ssq_kwrds)
    SS_resid = calc_ssq_fast(IHs, Gs, **ssq_kwrds)
    F = (SS_among/df_among)/(SS_resid/df_resid)
    return F
