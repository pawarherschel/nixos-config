# gui.theme.wallpaper — deterministic wallpaper selection from wallpaper repo.
# Uses git rev as seed, or generates an SVG from theme colors when dirty/local.
{ inputs, den, ... }:
{
  flake-file.inputs.wallpapers = {
    url = "github:pawarherschel/wallpapers";
    flake = false;
  };

  den.aspects.gui.theme.wallpaper = {
    includes = [
      den.aspects.overlays.palapply
    ];

    nixos =
      { pkgs, lib, ... }:
      let
        hasRev = inputs.self ? rev;

        # All colors from all 4 catppuccin variants via palapply's palette
        palette = builtins.fromJSON (builtins.readFile "${inputs.palapply}/palette.json");
        allColors =
          let
            sorted = lib.sort (a: b: a.hue < b.hue) (
              lib.concatMap
                (
                  name:
                  lib.mapAttrsToList (_: c: {
                    inherit (c) hex;
                    hue = c.oklch.h;
                  }) (lib.filterAttrs (_: c: c.accent) palette.${name}.colors)
                )
                [
                  "mocha"
                  "macchiato"
                  "frappe"
                  "latte"
                ]
            );
          in
          map (a: a.hex) sorted;

        # Pre-computed noise maps for palapply (deterministic from seed 67 + resolution)
        noiseMaps =
          pkgs.runCommand "palapply-noise-maps"
            {
              nativeBuildInputs = [
                pkgs.palapply
                pkgs.imagemagick
              ];
              outputHash = "sha256-SDkodFkvKQITeLV89lVv4upUXGJspijodtNQhEFAL4Q=";
              outputHashAlgo = "sha256";
              outputHashMode = "nar";
            }
            ''
              convert -size 1920x1080 xc:black dummy.png
              palapply --maps-dir "$out" --genmaps-only 1920 1080 --input dummy.png --output dummy.png
              rm dummy.png
            '';
        generated =
          let
            n = builtins.length allColors;
            rects = lib.concatStringsSep "\n" (
              lib.imap0 (i: c: ''<rect x="${toString i}" y="0" width="1" height="1" fill="${c}"/>'') allColors
            );
            svg = pkgs.writeText "theme-wallpaper.svg" ''
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${toString n} 1" width="1920" height="1080" preserveAspectRatio="none">
              ${rects}
              </svg>
            '';
          in
          pkgs.runCommand "theme-wallpaper.png"
            {
              nativeBuildInputs = with pkgs; [
                imagemagick
                librsvg
              ];
            }
            ''
              convert "${svg}" -resize 1920x1080 "$out"
            '';

        # Select a PNG from the wallpapers repo seeded by git rev
        selectedPng =
          let
            files = builtins.readDir inputs.wallpapers;
            pngs = builtins.sort (a: b: a < b) (
              builtins.attrNames (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".png" n) files)
            );
            count = builtins.length pngs;
          in
          if count > 0 then
            let
              hexVal = {
                "0" = 0;
                "1" = 1;
                "2" = 2;
                "3" = 3;
                "4" = 4;
                "5" = 5;
                "6" = 6;
                "7" = 7;
                "8" = 8;
                "9" = 9;
                "a" = 10;
                "b" = 11;
                "c" = 12;
                "d" = 13;
                "e" = 14;
                "f" = 15;
              };
              hash = builtins.hashString "sha256" (inputs.self.rev or "");
              sum = lib.foldl' builtins.add 0 (map (c: hexVal.${c}) (lib.stringToCharacters hash));
              index = lib.mod sum count;
            in
            builtins.elemAt pngs index
          else
            null;

        # Resize + palapply recolor pipeline
        pipeline =
          pkgs.runCommand "catppuccin-wallpaper.png"
            {
              nativeBuildInputs = [
                pkgs.palapply
                pkgs.imagemagick
              ];
            }
            ''
              src="${inputs.wallpapers}/${selectedPng}"
              convert "$src" -resize 1920x1080 resized.png
              palapply --maps-dir ${noiseMaps} -i resized.png -o "$out"
            '';

      in
      {
        stylix.image = if hasRev then pipeline else generated;
      };
  };
}
