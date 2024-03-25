variable "cmd" {}
variable "trigger_cmd" {
  type    = bool
  default = true
}
variable "trigger_paths" {
  type    = list(string)
  default = null
}
variable "trigger_strings" {
  type    = list(string)
  default = null
}
#———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
locals {
  session = md5(var.cmd)
}
#———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
data "external" "cmd" {
  program = ["python3", "-c", <<-eof
    import sys, json
    f = open("/tmp/${local.session}.sh", "w")
    f.write(json.load(sys.stdin)['cmd'])
    f.close()
    print('{"state": "ok"}')
  eof
  ]
  query = {
    cmd = sensitive(<<-eof
      set -e
      ${var.cmd}
    eof
    )
  }
}
#———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
resource "null_resource" "cmd" {
  triggers = {
    cmd     = var.trigger_cmd ? var.cmd : null
    strings = var.trigger_strings != null ? join("\n", var.trigger_strings) : null
    paths   = var.trigger_paths != null ? join("\n", flatten([for tpath in var.trigger_paths : [for file in fileset(".", tpath) : "\n\n[File]: ${file}:\n\n${file(file)}"]])) : null
  }
  provisioner "local-exec" {
    interpreter = ["bash"]
    command     = "/tmp/${local.session}.sh"
  }
  depends_on = [data.external.cmd]
}
#———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
