# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.step-ca.image_ref
        "config" = module.step-ca.config
        "tags"   = module.step-ca.tag_list
      }
  })
}

