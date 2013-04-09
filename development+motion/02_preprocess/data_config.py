#list of subjects that are to be excluded 
exclusionSubjectList = None

#list of subjects that are included 
subjectList = None # extract from all subjects

#Anatomical Path
#Put %s where site and subjects are in the path
anatomicalTemplate = '/home2/data/Projects/CWAS/development+motion/Originals/%s/%s/mprage.nii.gz'

#Functional Path
#Put  %s where site and subjects are in the path
functionalTemplate = '/home2/data/Projects/CWAS/development+motion/Originals/%s/%s/rest.nii.gz'

#list of sites
#if None extract data runs on all sites
siteList = None

#slice timing parameters csv file path
sliceTimingParametersCSV = 'slice_timing.csv'
