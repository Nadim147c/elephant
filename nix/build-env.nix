{
  lib,
  buildEnv,
  elephant-providers,
  elephant,
  wl-clipboard,
  libqalculate,
  imagemagick,
  fd,
  bluez,
  excludedProviders ? [
    "archlinuxpkgs"
    "dnfpackages"
    "aptpackages"
  ],
}:

let
  include =
    module: packages: lib.optionals (!(builtins.elem module excludedProviders)) (lib.toList packages);
  clis = [
    fd
    imagemagick
  ]
  ++ include "bluetooth" bluez
  ++ include "clipboard" [
    wl-clipboard
    imagemagick
  ]
  ++ include "calc" libqalculate;
in
buildEnv {
  pname = "elephant-with-providers";
  version = lib.trim (builtins.readFile ../cmd/elephant/version.txt);

  paths = [
    (elephant.override {
      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        (lib.makeBinPath clis)

        "--set-default"
        "ELEPHANT_PROVIDER_DIR"
        "${elephant-providers}/lib/elephant"
      ];
    })

    elephant-providers
  ];

}
