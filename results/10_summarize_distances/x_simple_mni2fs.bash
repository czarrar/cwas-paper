#!/usr/bin/env bash

if [[ "$#" -ne 2 ]]; then
    echo "usage: $0 input-volume output-prefix"
    echo "output-prefix will have either lh.mgh or rh.mgh appended to it"
fi

invol="$1"
prefix="$2"

hemis="lh rh"

for hemi in ${hemis}; do
    echo "hemi: ${hemi}"
    mri_vol2surf --mov ${invol} \
        --hemi ${hemi} \
        --mni152reg \
        --projfrac-max 0 1 0.1 \
        --interp trilinear \
        --out ${prefix}_${hemi}.mgh
    echo ""
done
