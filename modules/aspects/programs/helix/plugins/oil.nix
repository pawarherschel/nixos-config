# oil.hx edits the filesystem from its own buffer.
{ ... }:
{
  den.aspects.programs.helix.homeManager =
    { pkgs, ... }:
    {
      programs.nhx = {
        # Prefixing hx's PATH with coreutils supplies GNU stat, including on Darwin.
        requiredPackages = [
          pkgs.git
          pkgs.coreutils # mv, mkdir, cp, and stat --printf
        ];
        plugins.oil = {
          enable = true;
          # These controls apply only to *oil*, not the global editor keymap.
          config.keymaps.normal = {
            ret = ":oil-enter";
            backspace = ":oil-up";
            "C-s" = ":oil-save";
            q = ":oil-close";
          };
        };
      };
    };
}
