# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.caddy.image_ref
        "config" = module.caddy.config
        "tags"   = module.caddy.tag_list
      }
  })
}

