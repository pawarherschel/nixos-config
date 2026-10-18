# lsp-picker filters language-server logs through a shell and grep.
{ ... }:
{
  den.aspects.programs.helix.homeManager =
    { lib, pkgs, ... }:
    {
      programs.nhx = {
        requiredPackages = [
          pkgs.bash # The plugin invokes literal sh; no shell setter is exposed.
          pkgs.gnugrep
        ];
        plugins.lsp-picker = {
          enable = true;
          extra = ''
            (lsp-picker-set-grep-cmd! "${lib.getExe pkgs.gnugrep}")
          '';
        };
      };
    };
}
