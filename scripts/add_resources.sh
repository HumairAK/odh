#!/usr/bin/env bash

set -o nounset
set -o errexit
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR
set -o errtrace
set -o pipefail
# https://dwheeler.com/essays/filenames-in-shell.html#ifs
IFS=$'\n\t'
# This program's basename.
_BN="$(basename "${0}")"

#_dependencies(){
#  DIR="${BASH_SOURCE%/*}"
#  if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
#  . "$DIR/lib/add_resources.sh"
#}

_usage() {
  cat <<HEREDOC

Add a resource to the cluster-scope folder in the specified environment and cluster.

Usage:
  ${_BN}  [resource_type] [resource_name] [env] [cluster] -f [path_to_file]
  ${_BN}  [resource_type] [resource_name] [env] [cluster]
  ${_BN}  -h | --help
Options:
  -f --file   Path to resource file if adding a new file to any environment (one that does not already exist in cluster-scope folder).
  -h --help   Show this screen.
HEREDOC
}

#_extract_name_type(){
#  metadata_name=`yq e '.metadata.name' ${1}`
#  kind=`yq e '.kind' ${1}`
#  echo $metadata_name $kind
#}

_error(){
  echo ${1}
  _usage
  exit 1
}

_add_new_resource(){
  resource_type=${1:-}
  resource_name=${2:-}
  env=${3:-}
  cluster=${4:-}
  path_to_file=${6:-}

  destination_dir=cluster-scope/base/${resource_type}/${resource_name}

  if [[ -d "${destination_dir}" ]]
  then
    _error "Resource ${resource_name} of type ${resource_type} already exists, but the -f/--file option was used. To add this resource omit this flag."
  fi

  mkdir -p ${destination_dir}
  filename=${resource_type%?}.yaml
  cp ${path_to_file} ${destination_dir}/${filename}
  pushd ${destination_dir}
  kustomize init
  kustomize edit add resource ./${filename}
  popd
}

_add_resource_to_cluster(){
  resource_type=${1:-}
  resource_name=${2:-}
  env=${3:-}
  cluster=${4:-}

  pushd cluster-scope/overlays/${env}/${cluster}
  kustomize edit add resource ../../../base/${resource_type}/${resource_name}
  popd
}

_main() {
  if [[ "${1:-}" =~ ^-h|--help$  ]]
  then
    _usage
  elif [[ "${5:-}" =~ ^-f|--file$  ]]
  then
    _add_new_resource $@
    _add_resource_to_cluster $@
  else
    _add_resource_to_cluster $@
  fi
}

_main "$@"