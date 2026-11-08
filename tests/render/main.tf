# The instance's user_data, rendered from the template with stand-in values,
# so tests/posture.tftest.hcl can read the script the instance would run.
# The configuration renders it with timestamp(), which makes it unknown until
# apply; this renders the same template with every value known at plan.

terraform {
  required_version = ">= 1.9.2, < 2.0.0"
}

variable "password" {
  description = "A stand-in database password the assertions look for"
  type        = string
}

output "user_data" {
  value = templatefile("${path.module}/../../templates/user_data.sh.tpl", {
    timestamp                       = "2026-01-01T00:00:00Z"
    nextcloud_config_file           = "<?php $CONFIG = array ();"
    ebs_volume_1_name               = "/dev/xvdf"
    ebs_volume_1_mount_point        = "/mnt/nextcloud"
    backup_ebs_volume_1_name        = "/dev/xvdg"
    backup_ebs_volume_1_mount_point = "/mnt/backups"
    db_host_install                 = "db.example.test:5432"
    db_name_install                 = "nextclouddb"
    db_username_install             = "nextclouduser"
    db_password_install             = var.password
  })
}
