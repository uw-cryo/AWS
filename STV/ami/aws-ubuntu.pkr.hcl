packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "stv-dart"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name = "stv-dart-builder"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
    ]
    inline = [
      "echo Installing Apt Packages",
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get install -y bzip2 unzip x11-common",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "DATE=2022-05-18",
      "VERSION=3.1.0",
    ]
    inline = [
      "echo 'Installing Ames Stereo Pipeline (ASP)'",
      "NAME=StereoPipeline-$VERSION-$DATE-x86_64-Linux",
      "wget -q https://github.com/NeoGeographyToolkit/StereoPipeline/releases/download/$VERSION/$NAME.tar.bz2",
      "tar -xjf $NAME.tar.bz2",
      // to avoid permission denied error coming from 'stereo command'
      "sudo chmod +x /lib/x86_64-linux-gnu/libc.so.6",
      "sudo chown -R ubuntu:ubuntu /opt",
      "mv $NAME /opt/StereoPipeline",
      "rm $NAME.tar.bz2",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "CONDADIR=/opt/conda",
    ]
    inline = [
      "echo 'Installing MambaForge'",
      "wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh",
      "bash Mambaforge-Linux-x86_64.sh -b -p '$CONDADIR'",
      // can also do this as part of userdata script
      // https://stackoverflow.com/questions/31058233/why-cant-i-run-source-command-from-within-a-packer-build
      // ". $CONDADIR/etc/profile.d/conda.sh",
      // ". $CONDADIR/etc/profile.d/mamba.sh",
      "cp /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh",
      // "conda activate base",
      "rm Mambaforge-Linux-x86_64.sh",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo 'Installing AWSCLIv2'",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscliv2.zip",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "rm -rf aws awscliv2.zip",
    ]
  }

  # Upload DART Package to EC2 in order to install
  provisioner "file" {
    source      = "DART_5-8-12_2022-09-09_v1280_linux64.tar.gz"
    destination = "/home/ubuntu/DART_5-8-12_2022-09-09_v1280_linux64.tar.gz"
  }

  provisioner "shell" {
    environment_vars = [
      "DART=DART_5-8-12_2022-09-09_v1280_linux64",
    ]
    inline = [
      "echo 'Installing DART'",
      "tar -xvzf $DART.tar.gz",
      "cd $DART",
      "bash install-text.sh /opt/dart --move",
      "cd ../",
      "rm -rf DART_*",
    ]
  }


}
