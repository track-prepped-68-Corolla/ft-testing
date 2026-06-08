# =============================================================================
# disko — declarative disk layout for the example machine
# =============================================================================
#
# The framework generator injects inputs.Disko.nixosModules.disko into every
# machine, so this file only needs to populate disko.devices. Replace /dev/vda
# and the sizes with the real target disk before deploying a clone of this
# template (run `lsblk` on the target).
# =============================================================================
{ ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
