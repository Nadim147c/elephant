{
  lib,
  buildEnv,
  elephant,
  elephant-providers,
  bash,
  bluez,
  coreutils,
  fd,
  imagemagick,
  libqalculate,
  wl-clipboard,
  libnotify,
  tesseract,
  playerctl,
  excludedProviders ? [
    "archlinuxpkgs"
    "dnfpackages"
    "aptpackages"
  ],
}:

let
  include =
    module: packages: lib.optionals (!(builtins.elem module excludedProviders)) (lib.toList packages);
  # This doesn't handle all use cases but good enough
  clis = [
    coreutils
    bash
    wl-clipboard
    libnotify
  ]
  ++ include "files" fd
  ++ include "bluetooth" bluez
  ++ include "clipboard" [
    tesseract
    imagemagick
  ]
  ++ include "todo" playerctl
  ++ include "1password" playerctl
  ++ include "calc" libqalculate;

  providers = elephant-providers.override { inherit excludedProviders; };
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
        "${providers}/lib/elephant"
      ];
    })
    providers
  ];

}
