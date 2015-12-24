This repo is meant to be an example of how to easily set up an auto-scaling cluster of CoreOS machines running Couchbase and Sync Gateway nodes behind Nginx on AWS using https://terraform.io/

You may want to check out the README at [couchbase-cluster-go](https://github.com/tleyden/couchbase-cluster-go) for more background info.

Do a search across all the files in the repo for "XXX" in order to place proper values in them. You'll want to grab a new etcd discovery URL over at https://discovery.etcd.io/new and place it into *cloud-config.yaml* ...the other replacements should be pretty self-explantory however. You'd likely also want to do a find and replace for the AMI since they're constantly being updated.

To spin up your cluster, make sure you `cd` into this project's directory, then run `terraform apply`

Check on the status of your machines over at https://console.aws.amazon.com/ec2/v2/home, and once they're up log in with (putting in proper path to your .pem file, and proper IP for a machine in your newly spun up cluster):

`ssh -o StrictHostKeyChecking=no -i /XXX_PATH_TO_AWS_PEM_FILE_XXX/aws.pem -A core@XXX_AWS_IP_XXX`

Once you've SSHed in, run (using your own Sync Gateway config file):

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

To completely destroy the cluster, just run `terraform destroy -force`
