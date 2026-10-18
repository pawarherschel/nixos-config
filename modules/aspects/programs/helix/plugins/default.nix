# Steel plugins are packaged and pinned by nhx.
{ ... }:
{
  den.aspects.programs.helix.homeManager =
    { config, ... }:
    {
      home.sessionVariables.STEEL_HOME = "${config.home.homeDirectory}/.local/share/steel";
      programs.nhx.plugins = {
        smooth-scroll.enable = true;
        breadcrumbs.enable = true;
        context = {
          enable = true;
          extra = "(context-enable 'right)";
        };
        eval = {
          enable = true;
          requirePath = "eval.hx/eval.scm";
        };
        scopeline.enable = true;
        paredit = {
          enable = true;
          requirePath = "paredit.hx/paredit.scm";
        };
        previously = {
          enable = true;
          requirePath = "previously.hx/previously.scm";
        };
      };
    };
}
