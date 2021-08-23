#!/bin/bash

# expects a logged in cli, in path for  both 'az' & 'gcloud'

set -e

# https://cloud.google.com/compute/docs/instances/create-start-instance#gcloud
# https://cloud.google.com/community/tutorials/create-a-self-deleting-virtual-machine

# get an image name with
# gcloud compute images list

# e2-micro is a shared core cpu
location='australia-southeast1-b'
myupn=`az ad signed-in-user show --query mailNickname --output tsv`
# semi-random hostname generated with azure ad department i i.e security-34523
gcloudhost=`az ad signed-in-user show --query department --output tsv | tr '[:upper:]' '[:lower:]'`'-'${RANDOM}
# we run a post-boot script for setup. this is transparent and takes two or three minutes but WILL lock package-manager 'apt' - exclude if time-sentitive!
bootscript=`git rev-parse --show-toplevel`'/setups/debian.sh'

gcloud compute instances create ${gcloudhost} \
--quiet \
--preemptible \
--zone ${location} \
--boot-disk-size 12GB \
--labels job=${job_id} \
--boot-disk-auto-delete \
--machine-type e2-medium \
--boot-disk-type pd-ssd \
--metadata-from-file=startup-script=${bootscript} \
--description 'https://github.com/thetanz/scripts'

while sleep 2
do
   # immediatley after WM creation SSH is not available
   echo 'waiting for ssh to become available'
   # the setup script will run in the background and may take 
   # a few minutes to complete after initial shell provisioning
   gcloud compute ssh --quiet ${gcloudhost} --zone ${location} && break
done

# the host is set to be preemptive and will be suspended after 24hrs
# if for some reason this point in the script is not reached this should limit financial impact
# suspended preemptive machines do not delete by default - manual cleanup tasks.. 

gcloud --quiet compute instances delete ${gcloudhost} --zone=${location}
