# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.prometheus-logstash-exporter.image_ref
        "config" = module.prometheus-logstash-exporter.config
        "tags"   = module.prometheus-logstash-exporter.tag_list
      }
  })
}

