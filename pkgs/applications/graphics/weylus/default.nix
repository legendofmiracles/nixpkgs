{ lib,
  git,
  rustPlatform,
  fetchFromGitHub,
  dbus,
  ffmpeg,
  gst_all_1,
  xorg,
  libdrm,
  libva1,
  pkg-config,
  openssl,
  libpng,
  libcerf,
  pango,
  cairo,
  libGL,
  fltk,
  cmake,
  fetchgit,
  fetchFromGitLab,
  gnumake,
  nasm,
  which,
  autoconf,
  automake,
  libtool,
  nodePackages,
}:

rustPlatform.buildRustPackage rec {
  pname = "weylus";
  version = "0.11.2";

  src = fetchFromGitHub {
    owner = "H-M-H";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-o2uNT9f8nlxCCG2SiEfJDrbZqNP9KIyLJmV4P8xeasY=";
  };

  x264 = fetchFromGitLab {
    domain = "code.videolan.org";
    owner = "videolan";
    repo = "x264";
    rev = "stable";
    sha256 = "sha256-0M7dc1s9tVdmqB0d3u+Wmrksgb8I5Lz7jlJta/7Mnms=";
  };

  ffmpeg-source = fetchgit {
    url = "https://git.ffmpeg.org/ffmpeg.git";
    rev = "n4.4";
    sha256 = "sha256-q40sOzKMu27ePERKkrnKO0+LbZb+uTwgZtPJQdMTZSc=";
  };

  # maybe we should use the package, but the package uses the bleeding edge version, so not sure
  nv-headers = fetchgit {
    url = "https://git.videolan.org/git/ffmpeg/nv-codec-headers.git";
    sha256 = "sha256-5d6LCKQB31UZ0veanSeKJVrPkJ8o2nvQWRfIG8YuekM=";
  };

  # same goes for this
  libva = fetchFromGitHub {
    owner = "intel";
    repo = "libva";
    rev = "2.12.0";
    sha256 = "sha256-J4JhsgycUKpKxPyXL4bwvCcXhgb7TiqM1yUc0OUk2/0=";
  };

  patches = [
    ./dont-download.patch
    ./dont-clean.patch
    ./debug.patch
  ];

  postPatch = ''
    patchShebangs deps/*.sh
  '';

  preBuild = ''
    cd deps
    # copy because it has to be modified
    cp -r "${x264}" x264
    export AS=${lib.getBin nasm}/bin/nasm
    chmod -R 700 x264
    patchShebangs x264/configure

    cp -r "${ffmpeg-source}" ffmpeg
    chmod -R 700 ffmpeg
    patchShebangs ffmpeg/configure

    cp -r "${nv-headers}" nv-codec-headers
    cd nv-codec-headers
    chmod -R 700 .
    patch || cat Makefile.rej <<< cat <<EOF
    ${builtins.readFile ./set-permission-nv-headers.patch}
    EOF
    cd ..

    cp -r "${libva}" libva

    chmod -R 700 libva
  '';

  buildInputs = [ dbus ffmpeg gst_all_1.gst-plugins-base xorg.libXext xorg.libXft xorg.libXinerama xorg.libXcursor xorg.libXrender xorg.libXfixes libpng libcerf pango cairo libGL libdrm libva1 openssl fltk ];

  nativeBuildInputs = [ pkg-config cmake git which autoconf automake libtool nodePackages.typescript ];

  cargoSha256 = "sha256-XwLHcv0seeMkKXm7Bhve5/grr+13qAFtXbOHEiOID8g=";

  cargoBuildFlags = [ "--features=ffmpeg-system" ];

  meta = with lib; {
    description = "Use your tablet as graphic tablet/touch screen on your computer";
    homepage = "https://github.com/H-M-H/Weylus";
    license = with licenses; [ agpl3Only ];
    maintainers = with maintainers; [ legendofmiracles ];
  };
}
