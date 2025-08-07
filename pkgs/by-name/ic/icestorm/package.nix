{
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  pkg-config,
  libftdi1,
  python3,
  pypy3,

  # PyPy yields large improvements in build time and runtime performance, and
  # IceStorm isn't intended to be used as a library other than by the nextpnr
  # build process (which is also sped up by using PyPy), so we use it by default.
  # See 18839e1 for more details.
  usePyPy ? stdenv.hostPlatform.system == "x86_64-linux",
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "icestorm";
  version = "0-unstable-2025-06-03";

  passthru = rec {
    pythonPkg = if usePyPy then pypy3 else python3;
    pythonInterp = pythonPkg.interpreter;

    tests.examples = callPackage ./tests.nix {
      inherit (finalAttrs) pname src;
      icestorm = finalAttrs.finalPackage;
    };
  };

  src = fetchFromGitHub {
    owner = "YosysHQ";
    repo = "icestorm";
    rev = "f31c39cc2eadd0ab7f29f34becba1348ae9f8721";
    hash = "sha256-SLSxqgVsYMUxv8YjY1iRLnVFiIAhk/GKmZr4Ido0A3o=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    finalAttrs.passthru.pythonPkg
    libftdi1
  ];
  makeFlags = [
    "PREFIX=$(out)"
    "PYTHON3=${finalAttrs.passthru.pythonInterp}"
  ];

  enableParallelBuilding = true;

  # fix up the path to the chosen Python interpreter. for pypy-compatible
  # platforms, it offers significant performance improvements.
  patchPhase = ''
    for x in $(find . -type f -iname '*.py' -executable); do
      substituteInPlace "$x" \
        --replace-fail '/usr/bin/env python3' '${finalAttrs.passthru.pythonInterp}'
    done

    # We use GNU sed on Darwin, while icebox/Makefile assumed BSD sed (which
    # requires a (potentially empty) argument for the -i flag).
    substituteInPlace icebox/Makefile --replace-fail "sed -i '''" "sed -i"
  '';

  meta = {
    description = "Documentation and tools for Lattice iCE40 FPGAs";
    longDescription = ''
      Project IceStorm aims at reverse engineering and
      documenting the bitstream format of Lattice iCE40
      FPGAs and providing simple tools for analyzing and
      creating bitstream files.
    '';
    homepage = "https://github.com/YosysHQ/icestorm/";
    license = lib.licenses.isc;
    maintainers = with lib.maintainers; [
      shell
      thoughtpolice
    ];
    platforms = lib.platforms.all;
  };
})
