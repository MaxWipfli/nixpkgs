{
  lib,
  fetchFromGitHub,
  python3,
  ruby,
  libsForQt5,
  which,
  perl,
  libgit2,
  stdenv,
}:

stdenv.mkDerivation rec {
  pname = "klayout";
  version = "0.30.4-1";

  src = fetchFromGitHub {
    owner = "KLayout";
    repo = "klayout";
    rev = "v${version}";
    hash = "sha256-EhIGxiXqo09/p8mA00RRvKgXJncVr4qguYSPyEC0fqc=";
  };

  postPatch = ''
    patchShebangs .
  '';

  nativeBuildInputs = [
    libsForQt5.wrapQtAppsHook
    which
    perl
    python3
    ruby
  ];

  buildInputs = [
    libsForQt5.qtbase
    libsForQt5.qtmultimedia
    libsForQt5.qttools
    libsForQt5.qtxmlpatterns
    libgit2
  ];

  # explicitly set tool paths (qmake, python, ruby) to avoid auto-discovery which may find a non-Nix
  # version in $PATH first (if not building in the sandbox)
  configurePhase = ''
    runHook preConfigure
    mkdir -p $out/lib

    ./build.sh \
      -prefix $out/lib \
      -qmake ${libsForQt5.qtbase.dev}/bin/qmake \
      -python ${python3}/bin/python3 \
      -ruby ${ruby}/bin/ruby \
      -dry-run

    cd build-*
    runHook postConfigure
  '';

  enableParallelBuilding = true;

  # installPhase: `make install`, but everything goes into $out/lib/ as specified
  postInstall =
    lib.optionalString stdenv.hostPlatform.isLinux ''
      mkdir $out/bin
      mv $out/lib/klayout $out/bin/

      install -Dm444 ../etc/klayout.desktop -t $out/share/applications
      install -Dm444 ../etc/logo.png $out/share/icons/hicolor/256x256/apps/klayout.png
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p $out/Applications
      mv $out/lib/klayout.app $out/Applications/
    '';

  preFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    exec_name=$out/Applications/klayout.app/Contents/MacOS/klayout

    for lib in $out/lib/libklayout_*.0.dylib; do
      base_name=$(basename $lib)
      install_name_tool -change "$base_name" "@rpath/$base_name" "$exec_name"
    done

    wrapQtApp "$out/Applications/klayout.app/Contents/MacOS/klayout"
  '';

  meta = {
    description = "High performance layout viewer and editor with support for GDS and OASIS";
    mainProgram = "klayout";
    license = with lib.licenses; [ gpl2Plus ];
    homepage = "https://www.klayout.de/";
    changelog = "https://www.klayout.de/development.html#${version}";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ MaxWipfli ];
  };
}
