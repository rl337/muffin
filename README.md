# The Muffin Cluster Architecture

The Muffin Cluster architecture has the ambitious goal of running flexible virtualized clusters (in this case k3s and slurm) on heterogeneous small scale / embedded system hardware. 


## Abstraction of Boot Processes

A lot of small scale / embedded systems have different boot processes and run from sd cards or other devices that don't have a lot of write endurance. 

Muffin will use `das u-boot` to abstract boot processes and make it easy to load kernels and other boot resources (initrd, dtbs, etc) from tftp without requiring control of your dhcp and/or your dns.

The on bare metal distribution will be `alpine-linux` running a slimmed down memory-only footprint who's only purpose is to run hardware accelerated VMs that allow more flexible guest operating systems.

## Virtualization 

The actual "machines" in the muffin cluster are VMs controlled by `libvirt` and running in `QEMU` with kvm acceleration. 

Disks and other vm specific data are stored on durable (likely rotating disk) storage via NFS. 

## Cluster Partitioning

The fleet of VMs are partitioned into a k3s cluster for creating/running cluster resources and a slurm cluster for executing workloads.  Hardware can be reallocated as needed for various tasks. 



