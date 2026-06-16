# gui.niri.default-config — default niri binds, overridable per-host.
{ inputs, ... }:
{
  den.aspects.gui.niri.default-config = {
    provides.ksakura.homeManager =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      let
        defaultConfig = import "${inputs.niri}/default-config.kdl.nix" inputs;
        cfg = defaultConfig { inherit pkgs config lib; };
        bindsNode = lib.findFirst (n: n.name == "binds") null cfg.programs.niri.config;

        convertAction =
          action:
          if action.arguments == [ ] && action.properties == { } then
            { }
          else if action.properties == { } && builtins.length action.arguments == 1 then
            builtins.head action.arguments
          else if action.arguments == [ ] then
            action.properties
          else
            [ action.properties ] ++ action.arguments;

        defaultBinds = builtins.listToAttrs (
          map (bind: {
            inherit (bind) name;
            value.action.${(builtins.head bind.children).name} = convertAction (builtins.head bind.children);
          }) bindsNode.children
        );
      in
      {
        programs.niri.settings.binds = lib.mapAttrs (_: v: lib.mkDefault v) defaultBinds;
      };
  };
}
