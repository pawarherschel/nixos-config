{ lib, stdenvNoCC, bun, bun2nix, makeWrapper, buildNpmPackage, src, rev }:
let
  version = "unstable-${builtins.substring 0 7 rev}";
  webui = buildNpmPackage {
    pname = "connectome-host-webui";
    inherit version;
    src = "${src}/web";
    # The SPA imports shared protocol types from the sibling src directory.
    postUnpack = ''
      cp -r ${src}/src ./src
    '';
    npmDepsHash = "sha256-CJRDdNckkCLb0WYzfXk/IuuOvzaDpyU/87kb5cCcjd0=";
    npmFlags = [ "--ignore-scripts" ];
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r ../dist/web/. "$out/"
      runHook postInstall
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "connectome-host";
  inherit version src;
  nativeBuildInputs = [ bun2nix.hook makeWrapper ];
  bunDeps = bun2nix.fetchBunDeps { bunNix = ./bun.nix; };
  dontUseBunBuild = true;
  dontRunLifecycleScripts = true;
  bunInstallFlags = [ "--linker=hoisted" "--backend=copyfile" "--production" ];
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/connectome-host"
    cp -r src scripts recipes docs node_modules package.json README.md "$out/share/connectome-host/"
    mkdir -p "$out/share/connectome-host/dist/web"
    cp -r ${webui}/. "$out/share/connectome-host/dist/web/"
    makeWrapper ${lib.getExe bun} "$out/bin/connectome-host" \
      --prefix PATH : ${lib.makeBinPath [ bun ]} \
      --add-flags "$out/share/connectome-host/src/index.ts"
    runHook postInstall
  '';
  passthru = { inherit webui; };
  meta = {
    description = "Host for long-lived Connectome agents with terminal and browser interfaces";
    homepage = "https://github.com/anima-research/connectome-host";
    mainProgram = "connectome-host";
    platforms = lib.platforms.darwin;
  };
}
