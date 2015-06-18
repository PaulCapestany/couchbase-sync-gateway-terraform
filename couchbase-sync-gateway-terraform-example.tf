# the access_key and secret_key get read from the `terraform.tfvars` file
# `terraform.tfvars` is the only file that should *NOT* be committed!
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "us-east-1"
}

resource "aws_security_group" "example_security_group" {
    name = "example_sg"
    description = "Created via Terraform"

    ########################
    # AWS ALLOW ALL EGRESS #
    ########################

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ##################
    # STANDARD PORTS #
    ##################

    # SSH (personal IP address access only)
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["XXX_YOUR_PERSONAL_IP_ADDRESS_XXX/32"]
    }

    # HTTP access from anywhere
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ##########################
    # COUCHBASE SERVER PORTS #
    ##########################

    # Couchbase: Web Administration Port
    ingress {
        from_port = 8091
        to_port = 8091
        protocol = "tcp"
        self = true
    }

    # Couchbase: Web Administration Port (personal IP address access)
    ingress {
        from_port = 8091
        to_port = 8091
        protocol = "tcp"
        cidr_blocks = ["XXX_YOUR_PERSONAL_IP_ADDRESS_XXX/32"]
    }

    # Couchbase: Couchbase API Port
    ingress {
        from_port = 8092
        to_port = 8092
        protocol = "tcp"
        self = true
    }

    # Couchbase: 􏰧􏰆􏰈􏰑􏰉􏰆􏰊􏰖􏱆􏱁􏰌􏰈􏰑􏰉􏰆􏰊􏰖􏰀􏰥􏰏􏰜􏰗􏰑􏰈Internal/External Bucket Port for SSL
    ingress {
        from_port = 11207
        to_port = 11207
        protocol = "tcp"
        self = true
    }

    # Couchbase: Internal Bucket Port
    ingress {
        from_port = 11209
        to_port = 11209
        protocol = "tcp"
        self = true
    }

    # Couchbase: Internal/External Bucket Port
    ingress {
        from_port = 11210
        to_port = 11210
        protocol = "tcp"
        self = true
    }

    # Couchbase: Client Interface (proxy)
    ingress {
        from_port = 11211
        to_port = 11211
        protocol = "tcp"
        self = true
    }

    # Couchbase: Incoming SSL Proxy
    ingress {
        from_port = 11214
        to_port = 11214
        protocol = "tcp"
        self = true
    }

    # Couchbase: Internal Outgoing SSL Proxy
    ingress {
        from_port = 11215
        to_port = 11215
        protocol = "tcp"
        self = true
    }

    # Couchbase: Internal REST HTTPS for SSL
    ingress {
        from_port = 18091
        to_port = 18091
        protocol = "tcp"
        self = true
    }

    # Couchbase: Internal CAPI HTTPS for SSL
    ingress {
        from_port = 18092
        to_port = 18092
        protocol = "tcp"
        self = true
    }

    # Couchbase: Erlang Port Mapper (epmd)
    ingress {
        from_port = 4369
        to_port = 4369
        protocol = "tcp"
        self = true
    }

    # Couchbase: Node data exchange
    ingress {
        from_port = 21100
        to_port = 21299
        protocol = "tcp"
        self = true
    }
    
    ######################
    # SYNC GATEWAY PORTS #
    ######################

    # Sync Gateway: External
    ingress {
        from_port = 4984
        to_port = 4984
        protocol = "tcp"
        self = true
    }

    # Sync Gateway: Admin
    ingress {
        from_port = 4985
        to_port = 4985
        protocol = "tcp"
        self = true
    }

    # Sync Gateway: Admin (personal IP address access)
    ingress {
        from_port = 4985
        to_port = 4985
        protocol = "tcp"
        cidr_blocks = ["XXX_YOUR_PERSONAL_IP_ADDRESS_XXX/32"]
    }

    ################
    # COREOS PORTS #
    ################

    # CoreOS: etcd client communication
    ingress {
        from_port = 4001
        to_port = 4001
        protocol = "tcp"
        self = true
    }

    # CoreOS: etcd server-to-server communication
    ingress {
        from_port = 7001
        to_port = 7001
        protocol = "tcp"
        self = true
    }       
}

resource "aws_launch_configuration" "example_launch_config" {
    name = "example_lc"
    instance_type = "m3.medium"

    # the CoreOS AMI should be HVM, not PV. Use the Alpha channel => https://coreos.com/docs/running-coreos/cloud-providers/ec2/
    image_id = "ami-e7986c8c"

    # The connection block tells our provisioner how to
    # communicate with the resource (instance)
    connection {
        # The default username for our AMI
        user = "core"

        # The path to your keyfile
        key_file = "/XXX_PATH_TO_AWS_PEM_FILE_XXX/aws.pem"
    }  

    key_name = "XXX_YOUR_AWS_KEY_NAME_XXX"
    user_data = "${file("cloud-config.yaml")}"
    security_groups = ["${aws_security_group.example_security_group.id}"] 
}

resource "aws_autoscaling_group" "example_autoscaling_group" {
    depends_on = ["aws_launch_configuration.example_launch_config"]
    availability_zones = ["us-east-1b", "us-east-1c", "us-east-1e"]
    name = "example_asg"
    max_size = 5
    min_size = 2
    health_check_grace_period = 300
    health_check_type = "EC2"
    desired_capacity = 3
    force_delete = true
    launch_configuration = "${aws_launch_configuration.example_launch_config.id}"
}
