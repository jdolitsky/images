# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.docker-cli.image_ref
        "config" = module.docker-cli.config
        "tags"   = module.docker-cli.tag_list
      }
  })
}

