# helix.markdown — Markdown language + LSP config.
{ den, lib, ... }:
{
  den.aspects.programs.helix.markdown.homeManager = {
    programs.helix.languages = {
      language-server.ltex-ls-plus = {
        # command = "${pkgs.ltex-ls-plus}/bin/ltex-ls-plus";
        config.ltex = {
          language = "en-GB";
          additionalRules.enablePickyRules = true;
          completionEnabled = true;
          diagnosticSeverity = "warning";
          disabledRules."en-GB" = [
            "EN_QUOTES"
            "ELLIPSIS"
          ];
          statusBarItem = true;
        };
      };

      # language-server.marksman.command = "${lib.getExe pkgs.marksman}";

      language = [
        {
          name = "markdown";
          language-servers = [
            "ltex-ls-plus"
            # "marksman"
          ];
          # formatter = {
          #   command = "${lib.getExe pkgs.deno}";
          #   args = [ "fmt" "-" "--ext" "md" ];
          # };
          auto-format = true;
        }
      ];
    };
  };
}
