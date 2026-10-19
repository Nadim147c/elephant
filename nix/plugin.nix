{
  lib,
  buildGo127Module,
  protobuf,
  protoc-gen-go,
  wayland,
  parallel,
  excludedProviders ? [
    "archlinuxpkgs"
    "dnfpackages"
    "aptpackages"
  ],
}:

buildGo127Module (finalAttrs: {
  pname = "elephant-providers";
  version = lib.trim (builtins.readFile ../cmd/elephant/version.txt);

  src = lib.cleanSource (
    lib.fileset.toSource {
      root = ../.;
      fileset = lib.fileset.unions [
        ../cmd
        ../internal
        ../pkg
        ../go.mod
        ../go.sum
      ];
    }
  );

  vendorHash = "sha256-5AL1731OKp2AZgknZAvcfyL+TuU3DIPozjSItE5nOM8=";

  buildInputs = [
    wayland
  ];

  nativeBuildInputs = [
    protobuf
    protoc-gen-go
    parallel
  ];

  buildPhase = ''
    runHook preBuild

    EXCLUDE_LIST="${lib.concatStringsSep " " excludedProviders}"

    is_excluded() {
      target="$1"
      for e in $EXCLUDE_LIST; do
        [ -z "$e" ] && continue
        [ "$e" = "$target" ] && return 0
      done
      return 1
    }

    if [ -d ./internal/providers ]; then
      job_limit=""
      if [ -n "$NIX_BUILD_CORES" ] && [ "$NIX_BUILD_CORES" -gt 0 ]; then
        job_limit="$NIX_BUILD_CORES"
      else
        job_limit=1
      fi

      providers=""
      for dir in ./internal/providers/*; do
        [ -d "$dir" ] || continue
        provider=$(basename "$dir")
        is_excluded "$provider" && continue
        set -- "$dir"/*.go
        [ -e "$1" ] || continue
        providers="$providers $provider"
      done

      if [ -n "$providers" ]; then
        echo "$providers" | xargs -n1 | parallel -j "$job_limit" \
          'echo "Building provider: {}" && go build -buildmode=plugin -o "{}.so" ./internal/providers/"{}"' || exit 1
      fi
    fi

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/elephant/providers

    for so_file in *.so; do
      [ -f "$so_file" ] && cp "$so_file" "$out/lib/elephant/providers/"
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Elephant providers (Go plugins)";
    homepage = "https://github.com/abenz1267/elephant";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
})
