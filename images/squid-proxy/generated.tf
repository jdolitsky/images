# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.squid-proxy.image_ref
        "config" = module.squid-proxy.config
        "tags"   = module.squid-proxy.tag_list
      }
  })
}

