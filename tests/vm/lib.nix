# =============================================================================
# VM Test Shared Library
# =============================================================================
#
# Thin wrapper around the framework's VM test helpers.  The framework owns the
# input-merging, module-wiring, and sandbox-compatibility logic; this file only
# adds the test-specific baseline configuration that all smoke tests share.
#
# baseConfig — NixOS module added to every test node.  Pulls in the framework
#              module hub (via fw.lib.vmTestBase) and sets the minimum config
#              needed for a VM to boot: stateVersion, an admin password, and
#              Bluetooth suppression (no hardware in a VM).
#
# mkTest     — calls fw.lib.mkVmTest, which wraps runNixOSTest with the merged
#              input set in node.specialArgs so every node receives the same
#              `inputs` that real machines get from the generator.
# =============================================================================
{ inputs, ... }:
let
  fw = inputs.ft-framework;
  mkTest = fw.lib.mkVmTest inputs;
  baseConfig =
    { ... }:
    {
      imports = [ (fw.lib.vmTestBase inputs) ];
      ft.core.stateVersion = "25.05";
      ft.users.initialPasswords.admin = "test";
      hardware.bluetooth.enable = false;
    };
in
{
  inherit mkTest baseConfig;
}
