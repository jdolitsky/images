#!/usr/bin/env bash

# This script obtains the "h1:..." hashes for all platforms
# See https://github.com/hashicorp/terraform/issues/27264

set -o errexit; set -o nounset; set -o pipefail
export GOBIN="${PWD}/bin" PATH="${PWD}/bin:${PATH}"; TMPDIR="$(mktemp -d)"

# Note: All modules in the lockfile MUST have zips for these platforms
PLATFORMS=("darwin/amd64" "darwin/arm64" "linux/amd64" "linux/arm64")

# Create simple "zip-h1-hash" tool to calculate h1 hash from zip files
echo "[setup] building zip-h1-hash binary"
(mkdir -p zip-h1-hash && cd zip-h1-hash && echo '
    package main; import ( "fmt"; "os"; d "golang.org/x/mod/sumdb/dirhash" )
    func main() { h, _ := d.HashZip(os.Args[1], d.Hash1); fmt.Println(h) }
    ' > main.go && (go mod init zip-h1-hash 2>/dev/null || true) && 
    go mod tidy 2>/dev/null && go install .)

# Local installation of "tq" (github.com/jdolitsky/tq)
echo "[setup] installing tq"
go install github.com/jdolitsky/tq@27312f980cea7014f71fbb309fd99f75e808da6f # v0.3.0

# Rewrite .terraform.lock.hcl h1 hash entires, one provider at a time
for provider in $(tq '.body.blocks[] | select(.type == "provider").labels[0]' .terraform.lock.hcl | sed 's|registry.terraform.io/||'); do
    version="$(tq '.body.blocks[] | select(.labels[0] == "registry.terraform.io/'${provider}'").attributes["version"]' .terraform.lock.hcl | sed 's|"||g')"
    echo "[provider:${provider}] version: ${version}"
    zh_hashes=()
    h1_hashes=()
    for zh_hash in $(tq '.body.blocks[] | select(.labels[0] == "registry.terraform.io/'${provider}'").attributes["hashes"]' .terraform.lock.hcl | grep 'zh:' | cut -d'"' -f 2); do
        zh_hashes+=("${zh_hash}")
    done
    echo "[provider:${provider}] all zh hashes: ${zh_hashes[@]}"
    for platform in ${PLATFORMS[@]}; do
        meta_url="https://registry.terraform.io/v1/providers/${provider}/${version}/download/${platform}"
        echo "[provider:${provider}] fetching meta from ${meta_url}"
        zip_url="$(curl -sL "${meta_url}" | jq -r .download_url)"
        echo "[provider:${provider}] fetching zip from ${zip_url}"
        out="$(basename "${zip_url}")"
        curl -sLo "${TMPDIR}/${out}" "${zip_url}"
        h1_hash="$(zip-h1-hash "${TMPDIR}/${out}")"
        echo "[provider:${provider}] ${h1_hash} is the h1 hash for ${platform} based on ${out}"
        h1_hashes+=("${h1_hash}")
    done
    echo "[provider:${provider}] all h1 hashes: ${h1_hashes[@]}"
    v="";
    for h in $(echo "${h1_hashes[@]}" | tr ' ' '\n' | sort); do v="${v}\n\\\"${h}\\\","; done
    for h in $(echo "${zh_hashes[@]}" | tr ' ' '\n' | sort); do v="${v}\n\\\"${h}\\\","; done
    echo -e "# This file is maintained automatically by \"make tf-lockfile\".\n" > .terraform.lock.hcl.tmp
    tq '.body.blocks[] |= if (
        .labels[0] == "registry.terraform.io/'${provider}'"
    ) then (
        .attributes["hashes"] = "['${v}'\n]"
    ) else . end' .terraform.lock.hcl >> .terraform.lock.hcl.tmp
    mv .terraform.lock.hcl.tmp .terraform.lock.hcl
    echo "[provider:${provider}] hashes updated in .terraform.lock.hcl"
done
