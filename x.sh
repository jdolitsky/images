#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# We expect all modules we rely on to have zips for these platforms
PLATFORMS=("darwin/amd64" "darwin/arm64" "linux/amd64" "linux/arm64")

function build_h1hashgen() {
    [[ ! -f "h1hashgen/h1hashgen" ]] || return 0
    mkdir -p h1hashgen
    echo 'package main
    import ("fmt";"os";d "golang.org/x/mod/sumdb/dirhash")
    func main() {h, _ := d.HashZip(os.Args[1], d.Hash1);fmt.Println(h)}' > h1hashgen/main.go
    (cd h1hashgen && (go mod init h1hashgen 2>/dev/null || true) && go mod tidy 2>/dev/null && go build -o h1hashgen .)
}

function get_all_providers() {
    tq '.body.blocks[] | select(.type == "provider").labels[0]' .terraform.lock.hcl
}

function update_provider_h1_hashes() {
    provider="${1}"
    tmpdir="$(mktemp -d)"
    version="$(tq '.body.blocks[] | select(.type == "provider" and .labels[0] == "'${provider}'").attributes["version"]' .terraform.lock.hcl | sed 's|"||g')"
    echo "${provider}"
    for platform in ${PLATFORMS[@]}; do
        meta_url="$(echo "${provider}" | sed 's|registry.terraform.io/|https://registry.terraform.io/v1/providers/|')/${version}/download/${platform}"
        download_url="$(curl -sL "${meta_url}" | jq -r .download_url)"
        download_to="${tmpdir}/$(basename "${download_url}")"
        curl -sLo "${download_to}" "${download_url}"
        h1_hash="$(h1hashgen/h1hashgen "${download_to}")"
        echo "${h1_hash} (${platform})"
    done
    rm -rf "${tmpdir}"
}

function main() {
    build_h1hashgen
    for provider in $(get_all_providers); do
        update_provider_h1_hashes "${provider}"
    done
}

main
