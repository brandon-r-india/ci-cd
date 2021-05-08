if [ ${TAG} ]; then TAG=":${TAG}"; fi && run -u ${CUSER} --env=${ENV} --app=${APP} -I -p=3000:3000 --name=${APP} --rm local/rubyworld${TAG}
