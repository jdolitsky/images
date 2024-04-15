# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.fpm.image_ref
        "config" = module.fpm.config
        "tags"   = module.fpm.tag_list
      }
    },
    {
      basename(path.module) = {
        "ref"    = module.latest.image_ref
        "config" = module.latest.config
        "tags"   = module.latest.tag_list
      }
  })
}
