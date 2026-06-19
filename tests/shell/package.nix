# =============================================================================
# Shell Test Suite — Package
# =============================================================================
#
# Builds and runs the ft shell-recipe suite (shellcheck + bats unit and
# integration) against the framework's scripts/, reached through the
# ft-framework input. Exposed as packages.x86_64-linux.shell-tests so it stays
# out of `nix flake check`, like the VM smoke tests, and is run on demand via
# the Shell Tests workflow_dispatch job or:
#   nix build -L .#shell-tests
# =============================================================================
{ inputs, nixpkgs }:

let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  fw = inputs.ft-framework;
in
{
  shell-tests = pkgs.stdenvNoCC.mkDerivation {
    name = "ft-shell-tests";
    src = ./.;
    nativeBuildInputs = with pkgs; [
      bats
      shellcheck
      just
      jq
      git
      gnused
      gnugrep
      gawk
      coreutils
    ];
    dontConfigure = true;
    dontBuild = true;
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      export HOME="$TMPDIR"
      export GIT_CONFIG_NOSYSTEM=1
      export GIT_CONFIG_GLOBAL=/dev/null
      # The recipes/libs under test live in the framework input's scripts/.
      export FT_SCRIPTS_DIR="${fw}/scripts"
      bash ./run.sh
      runHook postCheck
    '';
    installPhase = "touch $out";
  };
}
