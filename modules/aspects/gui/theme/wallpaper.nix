# gui.theme.wallpaper — deterministic wallpaper selection from wallpaper repo.
# Uses git rev as seed, or generates an SVG from theme colors when dirty/local.
{ inputs, ... }:
{
  flake-file.inputs.wallpapers = {
    url = "github:pawarherschel/wallpapers";
    flake = false;
  };

  den.aspects.gui.theme.wallpaper = {
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        hasRev = inputs.self ? rev;

        # Parse a base24 YAML and get all baseXX hex colors directly from the file
        parseColors =
          path:
          let
            yaml = builtins.readFile path;
            matches = map builtins.head (
              builtins.filter (m: m != null) (
                map (line: builtins.match "  base[0-9a-fA-F]{2}: \"(#......)\".*" line) (lib.splitString "\n" yaml)
              )
            );
          in
          matches;

        # All colors from the 4 catppuccin variants
        allColors = lib.concatLists (
          map parseColors [
            "${inputs.tt-schemes}/base24/catppuccin-mocha.yaml"
            "${inputs.tt-schemes}/base24/catppuccin-macchiato.yaml"
            "${inputs.tt-schemes}/base24/catppuccin-frappe.yaml"
            "${inputs.tt-schemes}/base24/catppuccin-latte.yaml"
          ]
        );

        # PNG stripes for dirty rev — all theme colors as vertical stripes
        generated =
          let
            schemeColors = parseColors config.stylix.base16Scheme;
            n = builtins.length schemeColors;
            rects = lib.concatStringsSep "\n" (
              lib.imap0 (i: c: ''<rect x="${toString i}" y="0" width="1" height="1" fill="${c}"/>'') schemeColors
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

        # Resize + lutgen recolor pipeline
        pipeline =
          pkgs.runCommand "catppuccin-wallpaper.png"
            {
              nativeBuildInputs = [
                pkgs.lutgen
                pkgs.imagemagick
              ];
            }
            ''
              src="${inputs.wallpapers}/${selectedPng}"
              convert "$src" -resize 1920x1080 resized.png
              lutgen apply resized.png -o "$out" -- ${lib.escapeShellArgs allColors}
            '';

      in
      {
        stylix.image = if hasRev then pipeline else generated;
      };
  };
}
