# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.newrelic-k8s-events-forwarder.image_ref
        "config" = module.newrelic-k8s-events-forwarder.config
        "tags"   = module.newrelic-k8s-events-forwarder.tag_list
      }
  })
}

