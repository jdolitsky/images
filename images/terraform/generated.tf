# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.busl.image_ref
        "config" = module.busl.config
        "tags"   = module.busl.tag_list
      }
    },
    {
      basename(path.module) = {
        "ref"    = module.mpl.image_ref
        "config" = module.mpl.config
        "tags"   = module.mpl.tag_list
      }
  })
}

