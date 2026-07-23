{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.containers (rootless podman — the default cell): the dedicated service
  # account exists, the genuine docker-compose binary is on PATH (not
  # podman-compose), and DOCKER_HOST is wired to the rootless podman socket.
  vm-containers-rootless-podman = mkTest {
    name = "ft-containers-rootless-podman";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.containers.enable = true;
        # runtime = "podman" and rootless = true are the defaults; stated
        # explicitly for clarity about which cell this test exercises.
        ft.containers.runtime = "podman";
        ft.containers.rootless = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      # Dedicated rootless service account and group.
      machine.succeed("id podman")
      machine.succeed("getent group podman")
      # The genuine Docker Compose v2 binary, not podman-compose.
      machine.succeed("docker-compose version")
      # DOCKER_HOST is exported to login shells, pointing at the rootless socket.
      machine.succeed("bash -lc 'echo $DOCKER_HOST' | grep -q 'run/user/2000/podman/podman.sock'")
    '';
  };
}
