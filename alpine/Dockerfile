FROM alpine:latest

# base OS stuff
RUN apk add --no-cache bash python3 py3-yaml grep e2fsprogs

# archive tools
RUN apk add --no-cache mtools libarchive-tools gzip xorriso

# qemu related stuff
RUN apk add --no-cache qemu-x86_64 qemu-i386 openrc qemu-openrc qemu-img

WORKDIR /app
