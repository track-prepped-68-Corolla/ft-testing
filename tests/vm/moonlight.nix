{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.moonlight: the Sunshine backend installs a systemd *user* service, opens
  # the Moonlight port set in the firewall, and (with installClient) puts the
  # moonlight-qt client on PATH. GPU encode / KMS capture are hardware-dependent
  # and not exercised here — these three effects are assertable headlessly.
  vm-moonlight-load = mkTest {
    name = "ft-moonlight-load";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.moonlight = {
          enable = true;
          installClient = true;
        };
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")

      # The Sunshine host is a systemd user unit, generated system-wide under
      # /etc/systemd/user/ regardless of graphical login.
      machine.succeed("test -e /etc/systemd/user/sunshine.service")
      machine.succeed("grep -q sunshine /etc/systemd/user/sunshine.service")

      # openFirewall defaults to true — the Moonlight HTTP control port (47989)
      # must be reachable in the ruleset. Match across the iptables and nftables
      # backends so the assertion is backend-agnostic.
      machine.succeed(
          "{ iptables-save 2>/dev/null; nft list ruleset 2>/dev/null; } "
          "| grep -qw 47989"
      )

      # installClient = true installs the Moonlight viewer.
      machine.succeed("command -v moonlight")
    '';
  };
}
