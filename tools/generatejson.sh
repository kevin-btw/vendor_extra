#!/bin/bash
#
# Android ROM .json file generator
#
# Usage: ./generatejson.sh <json output> <ota zip>
#

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <json output> <ota zip>"
    exit 1
fi

JSON_FILE="$1"
ROM="$2"

if [ ! -f "$ROM" ]; then
    echo "Error: ROM file not found!"
    exit 1
fi

METADATA=$(unzip -p "$ROM" META-INF/com/android/metadata)
SDK_LEVEL=$(echo "$METADATA" | grep post-sdk-level | cut -f2 -d '=')
TIMESTAMP=$(echo "$METADATA" | grep post-timestamp | cut -f2 -d '=')

FILENAME=$(basename "$ROM")
DEVICE=$(echo "$FILENAME" | cut -f5 -d '-' | cut -f1 -d '.')
ROMTYPE=$(echo "$FILENAME" | cut -f4 -d '-')
DATE=$(echo "$FILENAME" | cut -f3 -d '-')
ID=$(echo "${TIMESTAMP}${DEVICE}${SDK_LEVEL}" | sha256sum | cut -f 1 -d ' ')
SIZE=$(du -b "$ROM" | cut -f1)
VERSION=$(echo "$FILENAME" | cut -f2 -d '-')
RELEASE_TAG="lineage-${VERSION}-${DATE}-${ROMTYPE}-${DEVICE}"

#  URL to point to the releases page
URL="https://github.com/kevin-btw/LineageOS-Releases/releases"

response=$(jq -n --arg datetime "$TIMESTAMP" \
        --arg filename "$FILENAME" \
        --arg id "$ID" \
        --arg romtype "$ROMTYPE" \
        --arg size "$SIZE" \
        --arg url "$URL" \
        --arg version "$VERSION" \
        '$ARGS.named'
)
wrapped_response=$(jq -n --argjson response "[$response]" '$ARGS.named')

JSON_OUTPUT_DIR=$(dirname "$JSON_FILE")

mkdir -p "$JSON_OUTPUT_DIR"
echo "$wrapped_response" > "$JSON_FILE"
git add "$JSON_FILE"
git commit -m "Update json file for $DEVICE-$VERSION-${DATE}"
git push -f
