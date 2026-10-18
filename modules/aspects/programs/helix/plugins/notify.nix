# Notify's cursor callback must return #false when no notification is focused.
{ ... }:
{
  den.aspects.programs.helix.homeManager =
    { config, ... }:
    {
      programs.nhx.plugins.notify = {
        enable = true;
        package = config.programs.nhx.availablePlugins.notify.overrideAttrs (previous: {
          postPatch = (previous.postPatch or "") + ''
            substituteInPlace notify.scm --replace-fail \
              '(if area (position (+ 3 (area-y area)) (+ 2 (area-x area))))' \
              '(if area (position (+ 3 (area-y area)) (+ 2 (area-x area))) #false)'
          '';
        });
      };
    };
}
