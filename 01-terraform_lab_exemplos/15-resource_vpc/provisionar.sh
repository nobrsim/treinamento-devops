#!/bin/bash

terraform init
terraform apply -auto-approve 
$(terraform output | grep "ssh -i")