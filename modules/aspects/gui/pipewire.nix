# gui.pipewire — PipeWire audio server.
{ den, ... }:
{
  den.aspects.gui.pipewire.nixos = {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
