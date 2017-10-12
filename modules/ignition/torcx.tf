data "ignition_file" "torcx" {
  filesystem = "root"
  path       = "/var/lib/torcx/store/docker:17.03.torcx.tgz"

  source {
    source = "http://builds.developer.core-os.net/torcx/pkgs/amd64-usr/docker/e26d62b370a142769b8364e006a37bf3c3127da9583e18deee08ebf4dcc15a460c5a51ccb967fdd565c3627ff086f96866fb36ff23a25f19fb02975403b0f3dd/docker:17.03.torcx.tgz"
    verification = "sha512-e26d62b370a142769b8364e006a37bf3c3127da9583e18deee08ebf4dcc15a460c5a51ccb967fdd565c3627ff086f96866fb36ff23a25f19fb02975403b0f3dd"
  }
}

data "template_file" "docker_profile" {
  template = <<EOF
{
  "kind": "profile-manifest-v0",
    "value": {
      "images": [{
        "name": "docker",
        "reference": "17.03"
      }]
   }
}
EOF
}

data "ignition_file" "docker_profile" {
  filesystem = "root"
  path       = "/etc/torcx/profiles/docker.json"

  content {
    content = "${data.template_file.docker_profile.rendered}"
  }
}

data "ignition_file" "next_profile" {
  filesystem = "root"
  path       = "/etc/torcx/next-profile"

  content {
    content = "docker"
  }
}
