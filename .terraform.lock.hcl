# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.
tq.body.blocks[] |= if (
        .labels[0] == "registry.terraform.io/chainguard-dev/apko"
    ) then (
        .attributes["hashes"] = "[\n\"h1:+DAq/FQbL6iBgCi0azPyd+BdCeGgj298+uNn3pWREL8=\",\n\"h1:Nbmf4fL5j/216iXNZmMAeh4WlVOAMWi1nvaZHOfyQro=\",\n\"h1:ZAxVcQUI8ZRDiYDd599YQPAyPhb/9Mj28EUjsmEL0oc=\",\n\"h1:pDYdU+HO6RchUNnGKiCVsp+3XFFS35Bfqre5mwTZ0Vg=\",\n\"zh:29d2d68a8c49c216e3f29070bdb2bc259420b6b4074f3c9300540b2add567573\",\n\"zh:35b3c7cc68a2a91572c1974660cf5dbf6a1acf907f1468650e256e6c18f193b5\",\n\"zh:890df766e9b839623b1f0437355032a3c006226a6c200cd911e15ee1a9014e9f\",\n\"zh:a23063b1111045c1ffee258683433777c069d6e8c63dffb1e882818445ad859f\",\n\"zh:ec0145598f7bf9c235faea0ffda227bb86432745f20902bbe0f8ed4ce0700c75\",\n]"
    ) else . end.terraform.lock.hcl