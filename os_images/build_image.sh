#!/bin/bash

sudo apt -y install qemu-system-x86-64 cloud-image-utils

# convert the user-data file into `cloud-init.img`
cloud-localds cloud-init.img user-data.yaml

rm -r base/
packer build base_image.pkr.hcl
gzip -6 base/base

# move to the shared folder with the assets server for the tinkerbell stack
sudo mv base/base.gz /var/lib/nomad/os_images/

rmdir base/
rm cloud-init.img
