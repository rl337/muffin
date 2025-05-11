

if [ -z "$BUILD_DIR" ]; then
    echo "BUILD_DIR is not set" 1>&2
    exit -1
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "BUILD_DIR $BUILD_DIR does not exist" 1>&2
    exit -2
fi

if [ -z "$DOWNLOAD_DIR" ]; then
    echo "DOWNLOAD_DIR is not set" 1>&2
    exit -3
fi

if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo "DOWNLOAD_DIR $DOWNLOAD_DIR does not exist" 1>&2
    exit -4
fi

if [ -z "$ALPINE_VERSION" ]; then
    echo "ALPINE_VERSION is not set" 1>&2
    exit -5
fi

if [ -z "$TYPE" ]; then
    echo "TYPE is not set" 1>&2
    exit -5
fi

case "$TYPE" in
    virt)
        TITLE="Virtual"
        ;;
    rpi)
        TITLE="Raspberry Pi Disk Image"
        ;;
    *)
        echo "TYPE $TYPE is not supported" 1>&2
        exit -6
esac

if [ -z "$ARCH" ]; then
    echo "ARCH is not set" 1>&2
    exit -7
fi


ALPINE_BASE_URL="https://dl-cdn.alpinelinux.org/alpine/$ALPINE_VERSION/releases/$ARCH/"
LATEST_RELEASES_YAML="$BUILD_DIR/latest-releases-$ALPINE_VERSION-$ARCH.yaml"
LATEST_RELEASES_URL="$ALPINE_BASE_URL/latest-releases.yaml"

SYS_LINUX_BASE_URL="https://www.kernel.org/pub/linux/utils/boot/syslinux"
LATEST_CHECKSUM_FILE="$BUILD_DIR/sha256sums.asc"
LATEST_CHECKSUM_URL="$SYS_LINUX_BASE_URL/sha256sums.asc"

download_file() {
    wget -O "$2" "$1"
    if [ $? -ne 0 ]; then
        echo "Could not download $2 from $1" 1>&2
        exit -1
    fi
}

compare_sha() {
    if [ ! -f "$1" ]; then
        echo "file $1 doesn't exist to sha" 1>&2
        return -1
    fi 

    ACTUAL_SHA=`sha256sum "$1" | cut -f1 -d\ `
    if [ "$ACTUAL_SHA" != "$2" ]; then
        echo "file $1 does not match sha. $2 != $ACTUAL_SHA"
        return -2
    fi

    return 0
}

extract_partitions() {
    IMG_FILE="$1"
    if [ ! -f "$IMG_FILE" ]; then
        echo  "'$IMG_FILE' doesn't exist" 1>&2
        exit -1
    fi

    FDISK_OUTPUT=`fdisk -l "$IMG_FILE"`
    if [ $? -ne 0 ]; then
        echo "fdisk failed on $IMG_FILE" 1>&2
        exit -2
    fi

    echo "$FDISK_OUTPUT"

    SECTOR_SIZE=`echo "$FDISK_OUTPUT" | grep 'Units: sectors of' | cut -f2 -d= | cut -f 1 -d/ | tr -d ' [a-z]'` 
    DOS_PARTITION=`echo "$FDISK_OUTPUT" | grep FAT32 | sed -e 's/[ ][ ]*/ /g' | cut -f2,4 -d\ `
    LINUX_PARTITION=`echo "$FDISK_OUTPUT" | grep Linux | sed -e 's/[ ][ ]*/ /g' | cut -f2,4 -d\ `

    echo "SECTOR_SIZE=$SECTOR_SIZE"
    echo "DOS_PARTITION=$DOS_PARTITION"
    echo "LINUX_PARTITION=$LINUX_PARTITION"
}

get_alpine_image() {
    IMAGE_TYPE="$1"
    IMAGE_TITLE="$2"
    IMAGE_VERSION="$3"
    IMAGE_ARCH="$4"
    find "$LATEST_RELEASES_YAML" -ctime +7 -print
    if [ $? -ne 0 ];  then
        download_file "$LATEST_RELEASES_URL" "$LATEST_RELEASES_YAML"
    fi

    LATEST_IMG_DATA=`cat "$LATEST_RELEASES_YAML" |  python -c 'import sys, yaml; y = [x for x in yaml.safe_load(sys.stdin.read()) if x["title"] == sys.argv[1]]; file=y[0]["file"]; sha=y[0]["sha256"]; version=y[0]["version"]; print(f"{file} {sha} {version}")' "$IMAGE_TITLE"`
    if [ $? -ne 0 ]; then
        echo "Could not extract image info from $LATEST_RELEASES_YAML" 1>&2
        exit -2
    fi

    LATEST_IMG_FILENAME=`echo "$LATEST_IMG_DATA" | cut -f 1 -d\ `
    LATEST_IMG_SHA=`echo "$LATEST_IMG_DATA" | cut -f 2 -d\ `
    LATEST_IMG_VERSION=`echo "$LATEST_IMG_DATA" | cut -f 3 -d\ `
    LATEST_IMG_FILE="$DOWNLOAD_DIR/$LATEST_IMG_FILENAME"

    UNPACK_NAME="${IMAGE_TYPE}-${IMAGE_ARCH}-${IMAGE_VERSION}"

    FILE_EXISTS=0
    if [ -f "$LATEST_IMG_FILE" ]; then
        compare_sha "$LATEST_IMG_FILE" "$LATEST_IMG_SHA"
        if [ $? -eq 0 ]; then
            echo "$LATEST_IMG_FILE already exists with sha $LATEST_IMG_SHA" 1>&2
            FILE_EXISTS=1
        fi
    fi

    if [ $FILE_EXISTS -eq 0 ]; then
        LATEST_IMG_FILE_URL="$ALPINE_BASE_URL/$LATEST_IMG_FILENAME"
        download_file "$LATEST_IMG_FILE_URL" "$LATEST_IMG_FILE"
        compare_sha "$LATEST_IMG_FILE" "$LATEST_IMG_SHA"    
    fi

    UNPACK_DIR="$BUILD_DIR/$UNPACK_NAME"
    case "$LATEST_IMG_FILE" in
        *.img.gz)
            IMG_FILE_UNCOMPRESSED="$BUILD_DIR/`basename "$LATEST_IMG_FILE" .gz`"
            cat "$LATEST_IMG_FILE" | gunzip > "$IMG_FILE_UNCOMPRESSED"
            mkdir -p "$UNPACK_DIR"
            mcopy -i "$IMG_FILE_UNCOMPRESSED" ::boot/* "$UNPACK_DIR"
            ;;
        *.iso)
            echo "ISO image"
            mkdir -p "$UNPACK_DIR"
            bsdtar -xf "$LATEST_IMG_FILE" -C "$UNPACK_DIR"
            strings "$LATEST_IMG_FILE" | grep -q "isolinux.bin"
            if [ $? -eq 0 ]; then
                dd if="$LATEST_IMG_FILE" of="$BUILD_DIR/${UNPACK_NAME}-isohdpfx.bin" bs=1 count=440
            fi
            ;;
        *)
            echo "Unknown image type: $LATEST_IMG_FILE" 1>&2
            exit -1
            ;;
    esac

    VMLINUZ_FILE="$BUILD_DIR/vmlinuz-${UNPACK_NAME}"
    if [ -f "$UNPACK_DIR/boot/vmlinuz-${IMAGE_TYPE}" ]; then
        cp "$UNPACK_DIR/boot/vmlinuz-${IMAGE_TYPE}" "$VMLINUZ_FILE"
    elif [ -f "$UNPACK_DIR/vmlinuz-${IMAGE_TYPE}" ]; then
        cp "$UNPACK_DIR/vmlinuz-${IMAGE_TYPE}" "$VMLINUZ_FILE"
    else
        echo "vmlinuz-${IMAGE_TYPE} not found in $UNPACK_NAME" 1>&2
        exit -1
    fi
    VMLINUZ_FILE_SIZE=`stat -c%s "$VMLINUZ_FILE"`
    INITRAMFS_FILE="$BUILD_DIR/initramfs-${UNPACK_NAME}"
    if [ -f "$UNPACK_DIR/boot/initramfs-${IMAGE_TYPE}" ]; then
        cp "$UNPACK_DIR/boot/initramfs-${IMAGE_TYPE}" "$INITRAMFS_FILE"
    elif [ -f "$UNPACK_DIR/initramfs-${IMAGE_TYPE}" ]; then
        cp "$UNPACK_DIR/initramfs-${IMAGE_TYPE}" "$INITRAMFS_FILE"
    else
        echo "initramfs-${IMAGE_TYPE} not found in $UNPACK_NAME" 1>&2
        exit -1
    fi
    INITRAMFS_FILE_SIZE=`stat -c%s "$INITRAMFS_FILE"`

    # extract actual kernel from efi stub
    KERNEL_FILE="$BUILD_DIR/vmlinuz-actual-${UNPACK_NAME}"
    KERNEL_OFFSET=`grep -abo $'\x1f\x8b\x08' "$VMLINUZ_FILE" | head -n 1 | cut -f 1 -d: | tr -d ' '`
    if [ $? -ne 0 ]; then
        echo "Could not find vmlinuz offset in $VMLINUZ_FILE" 1>&2
        exit -1
    fi
    KERNEL_OFFSET=$((KERNEL_OFFSET + 1))
    tail -c +$KERNEL_OFFSET "$VMLINUZ_FILE" | gunzip > "$KERNEL_FILE" 2>/dev/null
    KERNEL_FILE_SIZE=`stat -c%s "$KERNEL_FILE"`
    META_FILE="$BUILD_DIR/meta-${UNPACK_NAME}.txt"
    rm -f "$META_FILE"
    echo "IMAGE_TITLE=$IMAGE_TITLE" >> "$META_FILE"
    echo "IMAGE_TYPE=$IMAGE_TYPE" >> "$META_FILE"
    echo "IMAGE_VERSION=$LATEST_IMG_VERSION" >> "$META_FILE"
    echo "IMAGE_FILE=$LATEST_IMG_FILE" >> "$META_FILE"
    echo "UNPACK_NAME=$UNPACK_NAME" >> "$META_FILE"
    echo "VMLINUZ_FILE=$VMLINUZ_FILE" >> "$META_FILE"
    echo "INITRAMFS_FILE=$INITRAMFS_FILE" >> "$META_FILE"
    echo "UNCOMPRESSED_KERNEL=$KERNEL_FILE" >> "$META_FILE"
    echo "VMLINUZ_FILE_SIZE=$VMLINUZ_FILE_SIZE" >> "$META_FILE"
    echo "INITRAMFS_FILE_SIZE=$INITRAMFS_FILE_SIZE" >> "$META_FILE"
    echo "KERNEL_FILE_SIZE=$KERNEL_FILE_SIZE" >> "$META_FILE"
}

build_alpine_image() {
    IMAGE_TYPE="$1"
    IMAGE_VERSION="$2"
    IMAGE_ARCH="$3"
    
    IMAGE_NAME="${IMAGE_TYPE}-${IMAGE_ARCH}-${IMAGE_VERSION}"
    CHROOT_DIR="$BUILD_DIR/alpine-chroot-${IMAGE_NAME}"

    if [ -d "$CHROOT_DIR" ]; then
        echo "Chroot directory $CHROOT_DIR already exists" 1>&2
        return 0
    fi

    rc-update add qemu-binfmt default
    rc-service qemu-binfmt start

    mkdir -p "$CHROOT_DIR"
    if [ $? -ne 0 ]; then
        echo "Could not create chroot directory $CHROOT_DIR" 1>&2
        exit -1
    fi


    APK_CACHE_DIR="${DOWNLOAD_DIR}/apk-${IMAGE_NAME}"
    mkdir -p "$APK_CACHE_DIR"
    if [ $? -ne 0 ]; then
        echo "Could not create apk cache directory $APK_CACHE_DIR" 1>&2
        exit -1
    fi

    mkdir -p "$CHROOT_DIR/etc"
    cp /etc/resolv.conf $CHROOT_DIR/etc/

    mkdir -p "$CHROOT_DIR/etc/apk"
    cp /etc/apk/repositories $CHROOT_DIR/etc/apk/

    META_FILE="$BUILD_DIR/meta-${IMAGE_NAME}.txt"
    if [ ! -f "$META_FILE" ]; then
        echo "Meta file $META_FILE does not exist" 1>&2
        exit -1
    fi
    source "$META_FILE"
    echo "$IMAGE_VERSION" > "$CHROOT_DIR/etc/alpine-release"

    ISO_FILE="$BUILD_DIR/alpine-${IMAGE_NAME}.iso"
    if [ -f "$ISO_FILE" ]; then
        echo "ISO file $ISO_FILE already exists" 1>&2
        return 0
    fi

    ORIGINAL_ISO_DIR="$BUILD_DIR/$IMAGE_NAME"
    if [ ! -d "$ORIGINAL_ISO_DIR" ]; then
        echo "Original iso directory $ORIGINAL_ISO_DIR does not exist" 1>&2
        exit -1
    fi

    mkdir -p "$CHROOT_DIR/boot"
    if [ -d "$ORIGINAL_ISO_DIR/boot/syslinux" ]; then
        cp -a "$ORIGINAL_ISO_DIR/boot/syslinux" "$CHROOT_DIR/boot/syslinux"
    fi

    if [ -d "$ORIGINAL_ISO_DIR/boot/grub" ]; then
        cp -a "$ORIGINAL_ISO_DIR/boot/grub" "$CHROOT_DIR/boot/grub"
    fi

    if [ -d "$ORIGINAL_ISO_DIR/efi" ]; then
        cp -a "$ORIGINAL_ISO_DIR/efi" "$CHROOT_DIR/efi"
    fi

    if [ -d "$ORIGINAL_ISO_DIR/apks" ]; then
        cp -a "$ORIGINAL_ISO_DIR/apks" "$CHROOT_DIR/apks"
    fi

    apk --cache-dir add  -U --initdb --allow-untrusted \
        -p $CHROOT_DIR \
        --arch $IMAGE_ARCH \
        alpine-base
    if [ $? -ne 0 ]; then
        echo "Could not add alpine-base to chroot" 1>&2
        exit -2
    fi

    mount -t proc proc $CHROOT_DIR/proc/
    if [ $? -ne 0 ]; then
        echo "Could not mount proc" 1>&2
        exit -3
    fi
    mount -t sysfs sys $CHROOT_DIR/sys/
    if [ $? -ne 0 ]; then
        echo "Could not mount sys" 1>&2
        exit -4
    fi
    mount -o bind /dev $CHROOT_DIR/dev/
    if [ $? -ne 0 ]; then
        echo "Could not mount dev" 1>&2
        exit -5
    fi
    mount -o bind /dev/pts $CHROOT_DIR/dev/pts/
    if [ $? -ne 0 ]; then
        echo "Could not mount dev/pts" 1>&2
        exit -6
    fi
    mount -o bind /run $CHROOT_DIR/run/
    if [ $? -ne 0 ]; then
        echo "Could not mount run" 1>&2
        exit -7
    fi

    mkdir -p "$CHROOT_DIR/etc/apk/cache"
    if [ $? -ne 0 ]; then
        echo "Could not create apk cache directory $CHROOT_DIR/etc/apk/cache" 1>&2
        exit -8
    fi

    mount --bind "$APK_CACHE_DIR" "$CHROOT_DIR/etc/apk/cache"
    if [ $? -ne 0 ]; then
        echo "Could not mount apk cache directory $APK_CACHE_DIR" 1>&2
        exit -8
    fi
    
    chroot $CHROOT_DIR /bin/sh -c "apk add --no-cache cloud-init cloud-utils e2fsprogs-extra python3 py3-yaml py3-jsonpatch"
    if [ $? -ne 0 ]; then
        echo "Could not add cloud-init to chroot" 1>&2
        exit -8
    fi

    chroot $CHROOT_DIR /bin/sh -c "setup-cloud-init"

    umount $CHROOT_DIR/proc/
    umount $CHROOT_DIR/sys/
    umount $CHROOT_DIR/dev/pts/
    umount $CHROOT_DIR/dev/
    umount $CHROOT_DIR/run/



    EFI_IMG_OPTIONS=""
    if [ -f "$CHROOT_DIR/boot/grub/efi.img" ]; then
        EFI_IMG_OPTIONS="-eltorito-alt-boot -e /boot/grub/efi.img -no-emul-boot"
    fi

    ISOHYBRID_MBR_OPTION=""
    if [ -f "$CHROOT_DIR/boot/syslinux/isohdpfx.bin" ]; then
        ISOHYBRID_MBR_OPTION="-isohybrid-mbr $CHROOT_DIR/boot/syslinux/isohdpfx.bin -no-emul-boot -boot-load-size 4 -boot-info-table"
    fi

    ISOLINUX_OPTION=""
    if [ -f "$CHROOT_DIR/boot/syslinux/isolinux.bin" ]; then
        ISOLINUX_OPTION="-b /boot/syslinux/isolinux.bin"
    fi

    xorriso -as mkisofs \
        -o "$ISO_FILE" \
        $ISOHYBRID_MBR_OPTION \
        -c boot.catalog \
        -partition_offset 16 \
        $ISOLINUX_OPTION \
        $EFI_IMG_OPTIONS \
        -isohybrid-gpt-basdat \
        -isohybrid-apm-hfsplus \
        -R -J -V "ALPINE_ROOT" \
        "$CHROOT_DIR"

}

get_alpine_image "$TYPE" "$TITLE" "$ALPINE_VERSION" "$ARCH"

build_alpine_image "$TYPE" "$ALPINE_VERSION" "$ARCH"

