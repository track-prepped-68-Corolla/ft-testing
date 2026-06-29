{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.steamConfig: steam-config-nix's tmpfiles-managed app wrapper applies
  # the configured launch options. The patcher service itself needs a real
  # Steam userdata directory to patch against, which the sandboxed VM doesn't
  # have, so this asserts the wrapper-generation side instead: the symlink
  # exists and running it substitutes %command% and exports the configured
  # environment variable.
  vm-steam-config-load = mkTest {
    name = "ft-steam-config-load";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.steamConfig.enable = true;
        programs.steam.config.apps."620".launchOptionsStr = "FOO=bar %command%";
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("test -x /var/lib/steam-config-nix/apps/620/wrapper")
      machine.succeed('[ "$(/var/lib/steam-config-nix/apps/620/wrapper printenv FOO)" = bar ]')
    '';
  };
}
