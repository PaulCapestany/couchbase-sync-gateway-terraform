# Example of simplified DevOps using Terraform

This repo is meant to be an example of how to easily set up an auto-scaling cluster of [CoreOS](https://coreos.com/) machines running [Couchbase](http://www.couchbase.com/nosql-databases/couchbase-server) and [Sync Gateway](https://github.com/couchbase/sync_gateway) in [Docker](https://www.docker.com/) containers behind Nginx on AWS using [Terraform](https://terraform.io/).

You may want to check out the README at [couchbase-cluster-go](https://github.com/tleyden/couchbase-cluster-go) for more background info.

## Usage

Do a search across all the files in the repo for "XXX" in order to place proper values in them. You'll want to grab a new etcd discovery URL over at https://discovery.etcd.io/new and place it into *cloud-config.yaml* ...the other replacements should be pretty self-explanatory however. You'd likely also want to use an updated HVM [AMI](https://coreos.com/os/docs/latest/booting-on-ec2.html) to avoid immediate self-updates if you just want to quickly kick the tires.

To spin up your cluster, make sure you `cd` into this project's directory, then run `terraform apply`

Check on the status of your machines over at https://console.aws.amazon.com/ec2/v2/home, and once they're up log in (making sure to put in the proper path to your .pem file, and a proper IP for a machine in your newly spun up cluster):

`ssh -o StrictHostKeyChecking=no -i /XXX_PATH_TO_AWS_PEM_FILE_XXX/aws.pem -A core@XXX_AWS_IP_XXX`

Once you've SSHed in, run the following (making sure to use your own Sync Gateway config file):

```
etcdctl set /couchbase.com/enable-code-refresh true && \
sudo docker run --net=host tleyden5iwx/couchbase-cluster-go update-wrapper couchbase-fleet launch-cbs \
  --version latest \
  --num-nodes 3 \
  --userpass "user:passw0rd" \
&& \
sudo docker run --net=host tleyden5iwx/couchbase-cluster-go update-wrapper sync-gw-cluster launch-sgw \
  --launch-nginx \
  --num-nodes=3 \
  --config-url=http://XXX_YOUR_SYNC_GATEWAY_CONFIG_FILE/config.json \
  --create-bucket todos \
  --create-bucket-size 200 \
  --create-bucket-replicas 1
  ```

Here's a helpful command to sanity check the state of things in your cluster:

`docker ps -a && echo "" && fleetctl list-unit-files && echo "" && fleetctl list-units && echo "" && etcdctl ls / --recursive`

## Avoid unexpected AWS bills

***IMPORTANT:*** to completely destroy the cluster, run `terraform destroy -force`, otherwise you might get an unexpectedly more expensive AWS bill.
