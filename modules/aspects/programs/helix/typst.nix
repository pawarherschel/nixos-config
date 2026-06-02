# helix.typst — Typst language + LSP config + system package.
{ den, lib, ... }:
{
  den.aspects.programs.helix.typst = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.typstyle ];
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        programs.helix.languages = {
          language-server.tinymist.config = {
            typstExtraArgs = [
              "--features"
              "html"
            ];
            tinymist = {
              projectResolution = "lockDatabase";
              lint.enabled = true;
              lint.when = "onType";
              exportPdf = "onSave";
              systemFonts = false;
              preview.systemFonts = false;
              formatterIndentSize = 3;
              completion.triggerOnSnippetPlaceholders = true;
              preview = {
                background.enabled = false;
                background.args = [
                  "--invert-colors=never"
                  "--open"
                ];
              };
            };
          };

          language = [
            {
              name = "typst";
              language-servers = [
                "tinymist"
                # "ltex-ls-plus"
              ];
              formatter.command = lib.getExe pkgs.typstyle;
              auto-format = true;
              scope = "source.typst";
              file-types = [
                "typst"
                "typ"
              ];
              indent = {
                tab-width = 2;
                unit = "  ";
              };
              comment-token = "//";
              injection-regex = "typ(st)?";
              roots = [ "typst.toml" ];
              auto-pairs = {
                "(" = ")";
                "{" = "}";
                "[" = "]";
                "$" = "$";
                "\"" = "\"";
              };
            }
          ];
        };
      };
  };
}
