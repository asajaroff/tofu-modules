data "cloudinit_config" "debian" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = var.enable_ssm ? [1] : []
    content {
      filename     = "bootstrap-debian.sh"
      content_type = "text/x-shellscript"
      content      = var.custom_bootstrap_script != "" ? file(var.custom_bootstrap_script) : file("${path.module}/config/bootstrap-debian.sh")
    }
  }

  dynamic "part" {
    for_each = length(var.additional_ebs_volumes) > 0 ? [1] : []
    content {
      filename     = "mount-ebs.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/config/mount-ebs.sh.tpl", {
        volumes = var.additional_ebs_volumes
      })
    }
  }

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = var.custom_cloud_config != "" ? file(var.custom_cloud_config) : file("${path.module}/config/cloud-config-debian.yaml")
  }
}

data "cloudinit_config" "ubuntu" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = var.enable_ssm ? [1] : []
    content {
      filename     = "bootstrap-ubuntu.sh"
      content_type = "text/x-shellscript"
      content      = var.custom_bootstrap_script != "" ? file(var.custom_bootstrap_script) : file("${path.module}/config/bootstrap-ubuntu.sh")
    }
  }

  dynamic "part" {
    for_each = length(var.additional_ebs_volumes) > 0 ? [1] : []
    content {
      filename     = "mount-ebs.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/config/mount-ebs.sh.tpl", {
        volumes = var.additional_ebs_volumes
      })
    }
  }

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = var.custom_cloud_config != "" ? file(var.custom_cloud_config) : file("${path.module}/config/cloud-config-ubuntu.yaml")
  }
}

data "cloudinit_config" "freebsd" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = var.enable_ssm ? [1] : []
    content {
      filename     = "bootstrap-freebsd.sh"
      content_type = "text/x-shellscript"
      content      = var.custom_bootstrap_script != "" ? file(var.custom_bootstrap_script) : file("${path.module}/config/bootstrap-freebsd.sh")
    }
  }

  dynamic "part" {
    for_each = length(var.additional_ebs_volumes) > 0 ? [1] : []
    content {
      filename     = "mount-ebs.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/config/mount-ebs.sh.tpl", {
        volumes = var.additional_ebs_volumes
      })
    }
  }

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = var.custom_cloud_config != "" ? file(var.custom_cloud_config) : file("${path.module}/config/cloud-config-freebsd.yaml")
  }
}

data "cloudinit_config" "flatcar" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = var.enable_ssm ? [1] : []
    content {
      filename     = "bootstrap-flatcar.sh"
      content_type = "text/x-shellscript"
      content      = var.custom_bootstrap_script != "" ? file(var.custom_bootstrap_script) : file("${path.module}/config/bootstrap-flatcar.sh")
    }
  }

  dynamic "part" {
    for_each = length(var.additional_ebs_volumes) > 0 ? [1] : []
    content {
      filename     = "mount-ebs.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/config/mount-ebs.sh.tpl", {
        volumes = var.additional_ebs_volumes
      })
    }
  }

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = var.custom_cloud_config != "" ? file(var.custom_cloud_config) : file("${path.module}/config/cloud-config-flatcar.yaml")
  }
}

locals {
  # Map of OS family to cloudinit configuration
  cloudinit_map = {
    debian  = data.cloudinit_config.debian.rendered
    ubuntu  = data.cloudinit_config.ubuntu.rendered
    freebsd = data.cloudinit_config.freebsd.rendered
    flatcar = data.cloudinit_config.flatcar.rendered
  }

  selected_cloudinit = local.cloudinit_map[var.os_family]
}
