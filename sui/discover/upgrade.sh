#!/bin/bash

cmd="sui client upgrade --skip-dependency-verification --skip-fetch-latest-git-deps --upgrade-capability $1"
out=$($cmd)
#out=$(sui client --upgrade-capability)

if [ $? -eq 0 ]; then
    echo "$out"
else
    echo "$out"
    echo "Error: sui client publish failed."
    exit 1
fi

package_id=$(echo "$out"| sed -n '/Published Objects/,/Version/ s/.*PackageID: //p' )

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""

echo "PackageID:"
echo "$package_id"

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""