#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TMPDIR="$(mktemp -d)"

function build_h1hashgen() {
    if [[ -f "h1hashgen/h1hashgen" ]]; then
        return 0
    fi
    mkdir -p h1hashgen
    echo '
    package main
    import (
        "fmt"
        "os"
        "golang.org/x/mod/sumdb/dirhash"
    )
    func main() {
        hash, _ := dirhash.HashZip(os.Args[1], dirhash.Hash1)
        fmt.Println(hash)
    }' > h1hashgen/main.go
    (
        cd h1hashgen && \
        (go mod init h1hashgen 2>/dev/null || true) \
        && go mod tidy 2>/dev/null \
        && go build -o h1hashgen .\
    )
}

function get_all_providers() {
    tq '.body.blocks[] | select(.type == "provider").labels[0]' .terraform.lock.hcl
}

function update_provider_h1_hashes() {
    provider="${1}"
    version="$(tq '.body.blocks[] | select(.type == "provider" and .labels[0] == "'${provider}'").attributes["version"]' .terraform.lock.hcl | sed 's|"||g')"
    for variant in "darwin/amd64" "darwin/arm64" "linux/amd64" "linux/arm64"; do
        meta_url="$(echo "${provider}" | sed 's|registry.terraform.io/|https://registry.terraform.io/v1/providers/|')/${version}/download/${variant}"
        download_url="$(curl -sL "${meta_url}" | jq -r .download_url)"
        download_to="${TMPDIR}/$(basename "${download_url}")"
        curl -sLo "${download_to}" "${download_url}"
        h1hashgen/h1hashgen "${download_to}"
    done

}

function other() {
    return 0
        #meta_url="$(echo "${provider}" | sed 's|registry.terraform.io/|https://registry.terraform.io/v1/providers/|')/${version}"
    #echo "${meta_url}"
    #source="$(curl -sL "${meta_url}" | jq -r .source)"
    #echo "${source}"
    https://registry.terraform.io/v1/providers/chainguard-dev/apko/0.15.3
    for variant in "darwin/amd64" "darwin/arm64" "linux/amd64" "linux/arm64"; do
        url="$(echo "${provider}" | sed 's|registry.terraform.io/|https://registry.terraform.io/v1/providers/|')/${version}/download/${variant}"
        echo "${url}"
    done
}

function main() {
    build_h1hashgen
    for provider in $(get_all_providers); do
        update_provider_h1_hashes "${provider}"
    done
}

main


#for provider in $(tq '.body.blocks[] | select(.type == "provider").labels[0]' .terraform.lock.hcl); do
#    version="$(tq '.body.blocks[] | select(.type == "provider" and .labels[0] == "'${provider}'").attributes["version"]' .terraform.lock.hcl | sed 's|"||g')"
    #echo $provider $version

#    for variant in "darwin/amd64" "darwin/arm64" "linux/amd64" "linux/arm64"; do
#        url="$(echo "${provider}" | sed 's|registry.terraform.io/|https://registry.terraform.io/v1/providers/|')/${version}/download/${variant}"
#        echo "${url}"
#    done
#done
