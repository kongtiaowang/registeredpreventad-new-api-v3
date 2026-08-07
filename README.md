datalad install -r https://github.com/kongtiaowang/registeredpreventad-new-api-v3
cd registeredpreventad-new-api-v3
git config annex.http-headers-command "$(pwd)/tools/loris-auth.sh"   # must have
export LORIS_USERNAME=username                                       # access
export LORIS_PASSWORD=password
datalad get data/PREVENT-AD/sub-1000173/ses-NAPBL00/anat/sub-1000173_ses-NAPBL00_T1w_preventad_1000173_NAPBL00_t1w_001_t1w-defaced_001.mnc
