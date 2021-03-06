#!/bin/sh

set -o errexit
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR
set -o errtrace
set -o pipefail

if [ $# -lt 1 ] || [ "$#" == "--help" ] || [ "$#" == "-h" ] || [ ! -f "$1" ]; then
    echo "Change ClusterVersion manifest based on availableUpdates"
    echo -e "\nUsage: $0 PATH"
    echo -e "PATH\tPath to the ClusterVersion manifest to upgrade\n"
    exit 0
fi

echo "Updating resource file '$1'"

cluster_version=$(oc get -o yaml clusterversion/version)

available_updates=$(echo "$cluster_version" | yq e ".status.availableUpdates | length" -)
if [ $available_updates == "0" ]; then
    echo "No updates available"
fi

new_image=$(echo "$cluster_version" | yq e ".status.availableUpdates[0].image" -)
new_version=$(echo "$cluster_version" | yq e ".status.availableUpdates[0].version" -)

echo "Image:   $new_image"
echo "Version: $new_version"

yq e ".spec.desiredUpdate.image = \"$new_image\" | .spec.desiredUpdate.version = \"$new_version\"" -i $1
