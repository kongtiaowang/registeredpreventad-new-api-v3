datalad install -r https://github.com/kongtiaowang/registeredpreventad-new-api-v3

cd registeredpreventad-new-api-v3

git config annex.http-headers-command "$(pwd)/tools/loris-auth.sh"   # must have

export LORIS_USERNAME=username                                       # access
export LORIS_PASSWORD=password

datalad get .
