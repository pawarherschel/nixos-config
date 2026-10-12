# Installs the signed Apple Silicon release without modifying the app bundle.
{ ... }:
{
  den.aspects.overlays.codiff.darwin.nixpkgs.overlays = [
    (final: _prev: {
      codiff = final.stdenvNoCC.mkDerivation (attrs: {
        pname = "codiff";
        version = "1.16.2";

        src = final.fetchurl {
          url = "https://github.com/nkzw-tech/codiff/releases/download/v${attrs.version}/Codiff-darwin-arm64-${attrs.version}.zip";
          sha256 = "8a8f763614bfde19baa5859b37c5ab693d8060f24b181e3daa0845b63bfe70b5";
        };

        nativeBuildInputs = [ final.unzip ];
        sourceRoot = ".";
        dontConfigure = true;
        dontBuild = true;
        dontFixup = true;
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/Applications" "$out/bin"
          cp -R Codiff.app "$out/Applications/"
          ln -s "$out/Applications/Codiff.app/Contents/Resources/app/bin/codiff-app" "$out/bin/codiff"
          runHook postInstall
        '';

        meta = {
          description = "A fast local diff viewer";
          homepage = "https://github.com/nkzw-tech/codiff";
          license = final.lib.licenses.mit;
          mainProgram = "codiff";
          platforms = [ "aarch64-darwin" ];
          sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
        };
      });
    })
  ];
}
