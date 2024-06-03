# configuration.nix
{
  pkgs,
  modulesPath,
  website,
  config,
  ...
}: {
  imports = [
    # Adds availableKernelModules, kernelModules for instances running under QEMU (Ie Hetzner Cloud)
    (modulesPath + "/profiles/qemu-guest.nix")
    # Contains the configuration for the disk layout
    ./disk-config.nix
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Enable ssh access to the root user
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCowWxLVGvk6F1J/2vXcnJXpBu/9DSkAJ9gGX1vsDhKvVUoQZg41ABzWhisB/jmAiu4002FF1ed+UckJJ7F4FqrAMbXtw3BeyKpHH8Rl9WfDC4whFsg4MwsgPHSKg6AvSKrZh0tAY0dj4Pval/zzR5/FQ0ljkG+yBGr40RGLMXGbfu0xWHlANdhN+yGaGYaXtWZPxCW+PGwdgtXn2JKAzYjsJR6PCCdTki3/1+Ovr+I1mt6PT4qwgBV5VIWc9kwwAT5GQdifZHiCfxT6FCoPbtlqZv8h7TNEbGy3Aft3j5Aj2hRkd5eZ6ZhDIceoaLQwJzW5MKVC555+MbyuLzJ52c4daBgcH5mcn/SEuSB80HPmJdSg9D8bffC0XtO80EwOOZBpAhpblClId7CXRTEcJnssJdIVNFODLDd/p1qyK/jPqZzSdkLjpfmGuX65YIAmgpDjWe8BxZbCIjLspe5QVnjpeNCDK7DW5sTa9zwyYJ/0ghUSrHz79BC8tH62i7AOAfqB0N2gjv4ytKQ0eafbZZZFa9Ci7LqH0vj0xKsWP0PfyOpdtvVjfEBvz+Gk5w0VEfYuMlNLRkHHkLzbEO0R201R0M7eyypIWNFs3xXO5xXQOJtFA7/C8zNDNPpogiBT/J8VZtdDeB2Rr+3GSvaG8jpCJs572Q5j6IVUlho7hlk+w== openpgp:0xB0A185EE"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpITQKlC+lWz/famrrak90ElVzZV0pBn/WvtxojP5T5rNtfknlI1e1XI4aRrQCv7BAxS10vovDwTROt5ouVyS5pwC3BZLmKD5hPetEGKA4cXhbDmh9WDdK8dRoUqE0DCBZRi/zRBX1lqJMSUnqbPkdZv27uLV6NAbbIbytumbNanlNa3qmCy8ekMQTI9irYMXu6V1xng1Uqh16p6o/FofoUCDXwAsK2jxBs3QF5y/tSO9hNvFsTB4C9lAiCgXMIBQBZ71T2W02A1l713VQC+5nsfMM4UNSFpMffjeGsX/whism20tKZIVgm5RV7yjp7MVkb09RliNegmQeR2lsP20uzqUSraFl7yFB1qDF/rdZREMgXtIT3Yt3h0GCN/W/LLonUph0dO0B48vtM90gQafkG3fCjTXtYYDHNdFrh3CD+G4t/16efxSMQNvsdBpK0B5laQoHps5XGZLOkUhfzql0GrTLoHhlz19hCHXTsROstUOJjeOagT3iHvpKgu573JMIc1SRXWI0d6egeI6lsX7h4eGy6P9utwo5DaI0gVptN3LPwPRS/KP3gb6i1tvzkFLTlMpKPEyL7q9IO5JeKO6fRbVuHNSRjMvsGwS8xFWCmbqa8JPaPq3K4+NkxMluw1vRzsrkXW6eZYr1mnGTU/Tbc8HiJ+0fwRj8FdOfkshBSw== danielgafni16@gmail.com"
  ];

  environment.systemPackages = with pkgs; [
    helix
    zellij
    ripgrep
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  users.groups.acme.members = ["nginx"];
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin+acme@gafni.dev";

    # for testing
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  };

  services.nginx = {
    enable = true;
    statusPage = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    virtualHosts."gafni.dev" = {
      enableACME = true;
      forceSSL = true;
      root = "${website.packages.x86_64-linux.default}";
      locations."/".root = "${website.packages.x86_64-linux.default}";
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
      ];
      extraConfig = "error_page 404 /404.html;";
    };
    virtualHosts.${config.services.grafana.settings.server.domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        # Listening Address
        http_addr = "127.0.0.1";
        # and Port
        http_port = 3000;
        # Grafana needs to know on which domain and URL it's running
        domain = "grafana.gafni.dev";
        serve_from_sub_path = false;
      };
    };
  };

  services.prometheus = {
    enable = true;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
      };
      nginx = {
        enable = true;
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
      {
        job_name = "nginx";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.nginx.port}"];
          }
        ];
      }
    ];
  };

  system.stateVersion = "23.11";
}
