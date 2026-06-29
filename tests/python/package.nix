# =============================================================================
# Python Test Suite — Runnable
# =============================================================================
#
# Exposes packages.x86_64-linux.python-tests as a runnable wrapper (not a
# build-time check) that executes the ft_py pytest suite against the
# framework's already-built ft-py-test-env venv, reached through the
# ft-framework input. The venv has ft_py plus its dev dependency group
# (pytest, pytest-asyncio) already installed, so no Python toolchain is
# built or duplicated here.
#
#   nix run .#python-tests
# =============================================================================
{ inputs, nixpkgs }:

let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  fw = inputs.ft-framework;
in
{
  python-tests = pkgs.writeShellApplication {
    name = "python-tests";
    runtimeInputs = [ fw.packages.x86_64-linux.ft-py-test-env ];
    text = ''
      exec pytest -p no:cacheprovider "${./.}" "$@"
    '';
  };
}
