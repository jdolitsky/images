#!/usr/bin/env bash
set -o errexit; set -o nounset; set -o pipefail

# Note: all modules in lockfile MUST have zips for these platforms
PLATFORMS=("darwin/amd64" "darwin/arm64" "linux/amd64" "linux/arm64")
export GOBIN="${PWD}/bin" && export PATH="${GOBIN}:${PATH}"

function setup() {
    # Simple "h1hashgen" binary to create "h1:..." hashes
    (mkdir -p h1hashgen && cd h1hashgen && echo '
        package main; import ( "fmt"; "os"; d "golang.org/x/mod/sumdb/dirhash" )
        func main() { h, _ := d.HashZip(os.Args[1], d.Hash1); fmt.Println(h) }
        ' > main.go && (go mod init h1hashgen 2>/dev/null || true) && 
        go mod tidy 2>/dev/null && go build -o "${GOBIN}/h1hashgen" .)
    
    # Local install of "tq" (github.com/jdolitsky/tq)
    go install github.com/jdolitsky/tq@27312f980cea7014f71fbb309fd99f75e808da6f # v0.3.0
}

function list_providers_in_lockfile() {
    tq '.body.blocks[] | select(.type == "provider").labels[0]' .terraform.lock.hcl
}

function update_provider_hashes() {
    provider="${1}"; tmpdir="$(mktemp -d)" && trap "rm -rf "${tmpdir}"" EXIT
    version="$(tq '.body.blocks[] | select(.type == "provider" and .labels[0] == "'${provider}'").attributes["version"]' .terraform.lock.hcl | sed 's|"||g')"
    for platform in ${PLATFORMS[@]}; do
        meta_url="$(echo "${provider}" | sed 's|registry.terraform.io/|https://registry.terraform.io/v1/providers/|')/${version}/download/${platform}"
        download_url="$(curl -sL "${meta_url}" | jq -r .download_url)"
        download_to="${tmpdir}/$(basename "${download_url}")"
        curl -sLo "${download_to}" "${download_url}"
        h1_hash="$(h1hashgen/h1hashgen "${download_to}")"
        echo "${h1_hash} (${provider} | ${platform})"
    done
}

function main() {
    setup
    for provider in $(list_providers_in_lockfile); do
        update_provider_hashes "${provider}"
    done
}

main
