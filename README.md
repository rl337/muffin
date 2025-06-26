# The Muffin Cluster Architecture

The Muffin Cluster architecture has the ambitious goal of running flexible virtualized clusters (in this case k3s and slurm) on heterogeneous small scale / embedded system hardware. 


## Abstraction of Boot Processes

A lot of small scale / embedded systems have different boot processes and run from sd cards or other devices that don't have a lot of write endurance. 

There will be two main abstractions with regard to boot process.  The first will be hardware booting which involves getting hardware to the point where it can initialize itself over cloud-init (or specifically tiny-cloud) and the system boot process which involves the loading of the operating system.

* Hardware Boot Process

The Hardware boot process is a simplified net boot where we will pull our kernel and initramfs from TFTP. 

** Raspberry Pi Network Boot
For physical hardware, we primarily have Raspberry Pi 4 and 5 and both can boot the same way.  

Update the built in Bootloader of the Pi 4 or Pi 5.  For a Pi 3 or earlier you will need to use a bootloader on the SD Card to do this. 

```
BOOT_ORDER=0xf142
TFTP_PREFIX=1
TFTP_IP=x.x.x.x
```

The `TFTP_IP` is important in my case as I'm using my home router for DHCP which doesn't let me configure a tftp server.  This tells the Pi bootloader to make TFTP requests from this IP and not rely on one to be provided via DHCP.

The root of the TFTP server should have the following files from the [Raspberry Pi Firmware](https://github.com/raspberrypi/firmware/tree/master/boot) distribution.
* bcm2711-rpi-4-b.dtb 
* fixup4.dat 
* start4.elf

The Kernels used here will be the latest [Alpine netboot](https://dl-cdn.alpinelinux.org/latest-stable/releases/aarch64/netboot/) kernel/initrd that were specifically built for Raspberry Pi.
* initramfs-rpi
* vmlinuz-rpi

The following are configuration files which will be customized by our build scripts and represent configurations specific for the muffin project.
* cmdline.txt
* config.txt

To customize the builds I'm using an apkovl file.  This is a tarball of a base system constructed using the process below.
* apkovl.tar.gz

See [Netbooting Raspberry Pi](https://wiki.alpinelinux.org/wiki/Netbooting_Raspberry_Pi)

Generating an apkovl root filesystem from an `alpine:latest` container
* Run the container exposing current dir: `docker run --rm -v $PWD:/build -it alpine:latest sh`
* Create an initial directory: `mkdir /build/chroot`
* Create the etc directory in the chroot: `mkdir /build/chroot/etc`
* copy the container's apk configs into the chroot: `cp -r /etc/apk /build/chroot/etc`
* initialize apk in the chroot `apk --root=/build/chroot add --initdb`
* Update the apk inventory: `apk --root=/build/chroot update`
* Install alpine-base: `apk --root=/build/chroot add alpine-base`
* Perform customization steps here.
* Create tarball with compression: `tar -czf /build/apkovl.tar.gz -C /build/chroot .`

The customization in the second to last step can be done inline to the script but for this project I wanted a more robust way of customizing systems so I used Ansible playbooks.
Playbook steps for the Muffin architecture are:
* Setup chrony to address initial clock skews
* generate and supply ssh keys to the overlay
* setup cloud-init via tiny-cloud

## Virtualization 

The actual "machines" in the muffin cluster are VMs controlled by `libvirt` and running in `QEMU` with kvm acceleration. 

Disks and other vm specific data are stored on durable (likely rotating disk) storage via NFS. 

## Cluster Partitioning

The fleet of VMs are partitioned into a k3s cluster for creating/running cluster resources and a slurm cluster for executing workloads.  Hardware can be reallocated as needed for various tasks. 



