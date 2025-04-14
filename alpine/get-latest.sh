

if [ -z "$WORKING_DIR" ]; then
    echo "WORKING_DIR is not set" 1>&2
    exit -1
fi

if [ ! -d "$WORKING_DIR" ]; then
    echo "WORKING_DIR $WORKING_DIR does not exist" 1>&2
    exit -2
fi

ALPINE_BASE_URL="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/"
LATEST_RELEASES_YAML="$WORKING_DIR/latest-releases.yaml"
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

get_alpine_image() {
    find "$LATEST_RELEASES_YAML" -ctime +7 -print
    if [ $? -ne 0 ];  then
        download_file "$LATEST_RELEASES_URL" "$LATEST_RELEASES_YAML"
    fi

    LATEST_IMG_DATA=`cat "$LATEST_RELEASES_YAML" |  python -c 'import sys, yaml; y = [x for x in yaml.safe_load(sys.stdin.read()) if x["title"] == sys.argv[1]]; file=y[0]["file"]; sha=y[0]["sha256"]; print(f"{file} {sha}")' "$1"`
    if [ $? -ne 0 ]; then
        echo "Could not extract image info from $LATEST_RELEASES_YAML" 1>&2
        exit -2
    fi

    LATEST_IMG_FILENAME=`echo "$LATEST_IMG_DATA" | cut -f 1 -d\ `
    LATEST_IMG_SHA=`echo "$LATEST_IMG_DATA" | cut -f 2 -d\ `
    LATEST_IMG_FILE="$WORKING_DIR/$LATEST_IMG_FILENAME"
    if [ -f "$LATEST_IMG_FILE" ]; then
        compare_sha "$LATEST_IMG_FILE" "$LATEST_IMG_SHA"
        if [ $? -eq 0 ]; then
            echo "$LATEST_IMG_FILE already exists with sha $LATEST_IMG_SHA" 1>&2
        fi
        return 0
    fi

    LATEST_IMG_FILE_URL="$ALPINE_BASE_URL/$LATEST_IMG_FILENAME"
    download_file "$LATEST_IMG_FILE_URL" "$LATEST_IMG_FILE"
    compare_sha "$LATEST_IMG_FILE" "$LATEST_IMG_SHA"
}

get_alpine_image "Virtual"
get_alpine_image "Raspberry Pi Disk Image"



