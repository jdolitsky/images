# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.filebeat.image_ref
        "config" = module.filebeat.config
        "tags"   = module.filebeat.tag_list
      }
  })
}
