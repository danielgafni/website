terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secrets.enc.json"
}

provider "hcloud" {
  token = data.sops_file.secrets.data["HCLOUD_TOKEN"]
}

provider "cloudflare" {
  api_token = data.sops_file.secrets.data["CLOUDFLARE_API_TOKEN"]
}

# Configuration for SSH key to be used with Hetzner Cloud instances
resource "hcloud_ssh_key" "yubikey" {
  name       = "yubikey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCowWxLVGvk6F1J/2vXcnJXpBu/9DSkAJ9gGX1vsDhKvVUoQZg41ABzWhisB/jmAiu4002FF1ed+UckJJ7F4FqrAMbXtw3BeyKpHH8Rl9WfDC4whFsg4MwsgPHSKg6AvSKrZh0tAY0dj4Pval/zzR5/FQ0ljkG+yBGr40RGLMXGbfu0xWHlANdhN+yGaGYaXtWZPxCW+PGwdgtXn2JKAzYjsJR6PCCdTki3/1+Ovr+I1mt6PT4qwgBV5VIWc9kwwAT5GQdifZHiCfxT6FCoPbtlqZv8h7TNEbGy3Aft3j5Aj2hRkd5eZ6ZhDIceoaLQwJzW5MKVC555+MbyuLzJ52c4daBgcH5mcn/SEuSB80HPmJdSg9D8bffC0XtO80EwOOZBpAhpblClId7CXRTEcJnssJdIVNFODLDd/p1qyK/jPqZzSdkLjpfmGuX65YIAmgpDjWe8BxZbCIjLspe5QVnjpeNCDK7DW5sTa9zwyYJ/0ghUSrHz79BC8tH62i7AOAfqB0N2gjv4ytKQ0eafbZZZFa9Ci7LqH0vj0xKsWP0PfyOpdtvVjfEBvz+Gk5w0VEfYuMlNLRkHHkLzbEO0R201R0M7eyypIWNFs3xXO5xXQOJtFA7/C8zNDNPpogiBT/J8VZtdDeB2Rr+3GSvaG8jpCJs572Q5j6IVUlho7hlk+w== openpgp:0xB0A185EE"
}

resource "hcloud_firewall" "website_firewall" {
  name = "website-firewall"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

}

# Define a Hetzner Cloud Server resource for the website
resource "hcloud_server" "website" {
  name         = "website-instance"
  image        = "ubuntu-22.04" # After provisioning, NixOS will be installed see @install
  server_type  = "cpx11"        # AMD 2 vCPU, 2 GB RAM, 40 GB NVMe SSD
  location     = "fsn1"
  ssh_keys     = [hcloud_ssh_key.yubikey.id] # SSH keys associated with the server
  firewall_ids = [hcloud_firewall.website_firewall.id]
}

# Output the public IP address of the Hetzner Cloud Server
output "public_ip" {
  value = hcloud_server.website.ipv4_address
}

# Cloudflare DNS A record configuration for the website
# This is used for the website to be accessible directly via the IP ip address
# The website will be also accessible via the domain name behind the Cloudflare proxy
# See @website for the CNAME record and cloudflare_page_rule for the url
# This way the communication between Cloudflare and the website is encrypted
resource "cloudflare_record" "website_nginx" {
  zone_id = data.sops_file.secrets.data["CLOUDFLARE_ZONE_ID"]
  name    = "gafni.dev"
  value   = hcloud_server.website.ipv4_address
  type    = "A"
  proxied = false # Direct DNS, no Cloudflare proxy
}

# Cloudflare DNS CNAME record for the website behind Cloudflare proxy
resource "cloudflare_record" "website" {
  zone_id = data.sops_file.secrets.data["CLOUDFLARE_ZONE_ID"]
  name    = "@"
  value   = "gafni.dev"
  type    = "CNAME"
  proxied = true # Enable Cloudflare proxy
}

# Configure settings for the gafni.dev domain in Cloudflare
resource "cloudflare_zone_settings_override" "gafni-dev-settings" {
  zone_id = data.sops_file.secrets.data["CLOUDFLARE_ZONE_ID"]

  settings {
    tls_1_3                  = "on"
    automatic_https_rewrites = "on"
    ssl                      = "strict"
    cache_level              = "aggressive"
  }
}

# Cloudflare page rule for caching and optimizations
resource "cloudflare_page_rule" "website" {
  zone_id  = data.sops_file.secrets.data["CLOUDFLARE_ZONE_ID"]
  target   = "https://gafni.dev"
  priority = 1

  actions {
    cache_level = "cache_everything" # Cache HTML and other assets
  }
}

# NixOS system build module from Nixos anywhere
module "system-build" {
  source    = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute = ".#nixosConfigurations.website.config.system.build.toplevel"
}

# Module for disk partitioning script
module "disko" {
  source    = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute = ".#nixosConfigurations.website.config.system.build.diskoScript"
}

# Module for installing NixOS on the provisioned server
module "install" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.system-build.result.out
  nixos_partitioner = module.disko.result.out
  target_host       = hcloud_server.website.ipv4_address
}
