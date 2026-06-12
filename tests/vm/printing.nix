{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.printing: CUPS and Avahi daemon both reach the active state.
  vm-printing-load = mkTest {
    name = "ft-printing-load";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.printing.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      # cups.service is socket-activated — it shuts down after the printer
      # configuration script runs. Check the socket (always active) and verify
      # CUPS actually responds to a request instead.
      machine.wait_for_unit("cups.socket")
      machine.succeed("lpstat -r")
      machine.wait_for_unit("avahi-daemon.service")
    '';
  };
}
