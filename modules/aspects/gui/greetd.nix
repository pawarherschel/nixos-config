# gui.greetd — greetd display manager with tuigreet.
{ den, ... }:
{
  den.aspects.gui.greetd.nixos =
    { pkgs, ... }:
    {
      services.greetd = {
        enable = true;
        useTextGreeter = true;
        settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --greeting 'meow' --remember --remember-session";
        settings.default_session.user = "greeter";
      };
    };
}
