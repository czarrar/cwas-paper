#!/usr/bin/env python

import numpy as np
from pandas import DataFrame, read_csv, read_table
from patsy import dmatrices, dmatrix
from os import path
from collections import OrderedDict
import re

class GlmModel(object):
    """
    Generates the predictors and contrasts for a GLM
    """
    
    def __init__(self, formula, model_file, simple_con_file, pred_file, con_file):
        """
        Input filenames are model and simple contrasts.
        Argument formula is a formula.
        """
        super(GlmModel, self).__init__()
        self.formula = formula
        # TODO: check if input files exist
        self.model_file = model_file
        self.simple_con_file = simple_con_file
        # TODO: check output files don't exist
        self.pred_file = pred_file
        self.con_file = con_file
        # other stuff
        self.predictors = None
        self.contrasts = None
        self.di = None  # Design Info
    
    def gen_predictors(self):
        """Generates predictors data frame"""
        model = read_csv(self.model_file)
        _, predictors = dmatrices(self.formula, model)
        self.di = predictors.design_info
        self.predictors = DataFrame(predictors, columns=self.di.column_name_indexes)
        return self.predictors
    
    def gen_contrasts(self):
        """Generates contrasts data frame (requires predictors)"""
        if self.predictors is None: self.gen_predictors()
        
        # Read in data
        simple_contrasts = read_table(self.simple_con_file, sep=' ')
        
        # Create output
        n_cons = simple_contrasts.shape[0]; n_preds = self.predictors.shape[1]
        contrasts = DataFrame(np.zeros((n_cons, n_preds)), 
                              index = simple_contrasts['con'],  
                              columns = self.di.column_name_indexes)
        
        # Clean up the term names (take out 'center()')
        term_name_slices = OrderedDict()
        for k,v in self.di.term_name_slices.iteritems():
            m = re.search('center\((\w+)\)', k)
            if m is not None: k = m.group(1)
            term_name_slices[k] = v
        
        # Store values
        for i, row in simple_contrasts.iterrows():
            # i = 0; row = simple_contrasts.xs(i)   # for testing
            s = term_name_slices[row['term']]
            contrasts.ix[i,s] = row['value']
        
        self.contrasts = contrasts
        return contrasts
    
    def run(self):
        """Generates predictors and contrasts if they don't exist"""
        if self.predictors is None: self.gen_predictors()
        if self.contrasts is None: self.gen_contrasts()
    
    def rerun(self):
        """Runs predictors and contrast even if they exist"""
        self.predictors = None
        self.contrasts = None
        self.run()
    
    def save(self):
        """Saves output"""
        self.predictors.to_csv(self.pred_file, sep=" ")
        self.contrasts.to_csv(self.con_file, sep=" ")
    


