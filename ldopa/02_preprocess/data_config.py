#list of subjects that are to be excluded 
exclusionSubjectList = None

#list of subjects that are included 
subjectList = None # extract from all subjects

#Anatomical Path
#Put %s where site and subjects are in the path
anatomicalTemplate = '/home2/data/Originals/%s/%s/anat/mprage.nii.gz'

#Functional Path
#Put  %s where site and subjects are in the path
functionalTemplate = '/home2/data/Originals/%s/%s/*/func.nii.gz'

#list of sites
#if None extract data runs on all sites
siteList = 'site_list.txt'

#slice timing parameters csv file path
sliceTimingParametersCSV = 'slice_timing.csv'
