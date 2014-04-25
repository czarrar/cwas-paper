connectir_glm.R --ztransform \
 --forks 1 \
 --threads 12 \
 --memlimit 30 \
 --infuncs1 /home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104/short_compcor_funcpaths_4mm_fwhm08.txt \
 --threads 12 \
 --regressors /home2/data/Projects/CWAS/share/nki/07_glm/y_predictors.txt \
 --brainmask1 /home2/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz \
 --contrasts /home2/data/Projects/CWAS/share/nki/07_glm/y_contrasts.txt \
 /home2/data/Projects/CWAS/nki/glm/short_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08

connectir_glm.R --ztransform \
 --forks 1 \
 --threads 12 \
 --memlimit 30 \
 --infuncs1 /home2/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104/medium_compcor_funcpaths_4mm_fwhm08.txt \
 --threads 12 \
 --regressors /home2/data/Projects/CWAS/share/nki/07_glm/y_medium_predictors.txt \
 --brainmask1 /home2/data/Projects/CWAS/nki/rois/mask_gray_4mm.nii.gz \
 --contrasts /home2/data/Projects/CWAS/share/nki/07_glm/y_medium_contrasts.txt \
 /home2/data/Projects/CWAS/nki/glm/medium_compcor_kvoxs_fwhm08_to_kvoxs_fwhm08
