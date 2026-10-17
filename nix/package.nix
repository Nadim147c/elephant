{
  lib,
  buildGo127Module,
  protobuf,
  protoc-gen-go,
  makeWrapper,
  fd,
  coreutils,
  bash,
  makeWrapperArgs ? [ ],
}:

buildGo127Module (finalAttrs: {
  pname = "elephant";
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
    protobuf
  ];

  nativeBuildInputs = [
    protoc-gen-go
    makeWrapper
  ];

  propagatedBuildInputs = [
    fd
    coreutils
    bash
  ];

  subPackages = [
    "cmd/elephant"
  ];

  postFixup = ''
    wrapProgram $out/bin/elephant \
      --prefix PATH : ${lib.makeBinPath finalAttrs.propagatedBuildInputs} \
      ${lib.escapeShellArgs makeWrapperArgs}
  '';

  meta = with lib; {
    description = "Powerful data provider service and backend for building custom application launchers";
    homepage = "https://github.com/abenz1267/elephant";
    license = licenses.gpl3Only;
    maintainers = [ ];
    platforms = platforms.linux;
  };
})
