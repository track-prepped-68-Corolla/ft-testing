# =============================================================================
# Shell Test Suite — Runnable
# =============================================================================
#
# Exposes packages.x86_64-linux.shell-tests as a runnable wrapper (not a
# build-time check) that executes the ft shell-recipe suite — shellcheck + bats
# unit and integration — against the framework's scripts/, reached through the
# ft-framework input.
#
# It must run OUTSIDE the Nix build sandbox: the framework recipes, the test
# mocks, and the helper scripts are all executed via their `#!/usr/bin/env bash`
# shebangs, and the sandbox has no /usr/bin/env. Running it as a `nix run`
# program (on the CI runner / a dev machine, where /usr/bin/env exists) avoids
# that, while the toolchain still comes hermetically from this derivation.
#
#   nix run .#shell-tests            # all
#   nix run .#shell-tests -- unit    # a subset (unit | integration | lint)
# =============================================================================
{ inputs, nixpkgs }:

let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  fw = inputs.ft-framework;
in
{
  shell-tests = pkgs.writeShellApplication {
    name = "shell-tests";
    runtimeInputs = with pkgs; [
      bash
      bats
      shellcheck
      just
      jq
      git
      gnused
      gnugrep
      gawk
      findutils
      coreutils
    ];
    text = ''
      # The recipes/libs under test live in the framework input's scripts/.
      export FT_SCRIPTS_DIR="${fw}/scripts"
      exec bash "${./.}/run.sh" "$@"
    '';
  };
}
