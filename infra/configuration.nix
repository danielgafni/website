# configuration.nix
{ modulesPath, ... }: {
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
  ];

  users.users.root.password = "initial";

  system.stateVersion = "23.11";
}
