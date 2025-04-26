

if [ -z "$WORKING_DIR" ]; then
    echo "WORKING_DIR is not set" 1>&2
    exit -1
fi

if [ ! -d "$WORKING_DIR" ]; then
    echo "WORKING_DIR $WORKING_DIR does not exist" 1>&2
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

if [ -z "$TYPE" ]; then
    echo "TYPE is not set" 1>&2
    exit -5
fi

if [ -z "$TITLE" ]; then
    echo "TITLE is not set" 1>&2
    exit -6
fi




ALPINE_BASE_URL="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/"
LATEST_RELEASES_YAML="$DOWNLOAD_DIR/latest-releases.yaml"
LATEST_RELEASES_URL="$ALPINE_BASE_URL/latest-releases.yaml"

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

    UNPACK_NAME="${IMAGE_TYPE}-${LATEST_IMG_VERSION}"

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

    case "$LATEST_IMG_FILE" in
        *.img.gz)
            IMG_FILE_UNCOMPRESSED="$WORKING_DIR/`basename "$LATEST_IMG_FILE" .gz`"
            cat "$LATEST_IMG_FILE" | gunzip > "$IMG_FILE_UNCOMPRESSED"
            mkdir -p "$WORKING_DIR/$UNPACK_NAME"
            mcopy -i "$IMG_FILE_UNCOMPRESSED" ::boot/* "$WORKING_DIR/$UNPACK_NAME"
            ;;
        *.iso)
            echo "ISO image"
            mkdir -p "$WORKING_DIR/$UNPACK_NAME"
            bsdtar -xf "$LATEST_IMG_FILE" -C "$WORKING_DIR/$UNPACK_NAME"
            ;;
        *)
            echo "Unknown image type: $LATEST_IMG_FILE" 1>&2
            exit -1
            ;;
    esac
    META_FILE="$WORKING_DIR/$TYPE-meta.txt"
    rm -f "$META_FILE"
    echo "IMAGE_TITLE=$IMAGE_TITLE" >> "$META_FILE"
    echo "IMAGE_TYPE=$IMAGE_TYPE" >> "$META_FILE"
    echo "IMAGE_VERSION=$LATEST_IMG_VERSION" >> "$META_FILE"
    echo "IMAGE_FILE=$LATEST_IMG_FILE" >> "$META_FILE"
    echo "UNPACK_NAME=$UNPACK_NAME" >> "$META_FILE"
}

get_alpine_image "$TYPE" "$TITLE"



