# opencode.zenfeed — RSS pipeline with Ollama + Zenfeed podman container.
_: {
  den.aspects.programs.opencode.zenfeed = {

    nixos =
      { pkgs, lib, ... }:
      let
        dataDir = "/var/lib/zenfeed";
        configDir = "${dataDir}/config";
        configFile = "${configDir}/config.yaml";
        opmlPath = "/home/ksakura/.config/opencode/feeds.opml";

        configGenNu = pkgs.writeText "zenfeed-config.nu" ''
            let opml = ($env.OPML_PATH? | default "/home/ksakura/.config/opencode/feeds.opml")
            let out = ($env.CONFIG_OUT? | default "/var/lib/zenfeed/config/config.yaml")

            if ($out | path exists) {
              print "Config already exists, skipping generation."
              exit 0
            }

            if not ($opml | path exists) {
              print "OPML file not found, writing minimal config."
              let minimal = "llms:\n  - name: local-gen\n    default: true\n    provider: openai\n    endpoint: http://127.0.0.1:11434/v1\n    model: qwen3:8b\n    api_key: ollama\n  - name: local-embed\n    provider: openai\n    endpoint: http://127.0.0.1:11434/v1\n    embedding_model: nomic-embed-text\n    api_key: ollama\napi:\n  mcp:\n    address: \":1301\"\nscrape:\n  past: 8760h\n  interval: 1h\n  sources: []\nstorage:\n  feed:\n    retention: 730d\n    embedding_llm: local-embed\n"
              $minimal | save --force $out
              exit 0
            }

            print $"Generating Zenfeed config from ($opml)..."
            let xml = open --raw $opml | from xml

          let bodyChildren = (
            $xml
            | get content
            | where tag == "body"
            | first
            | get content
          )

          def collect-outlines [items] {
            $items | each {|item|
              if ($item.tag == "outline") {
                if ($item.attributes.xmlUrl? | is-not-empty) {
                  [{name: ($item.attributes.title? | default "untitled"), url: $item.attributes.xmlUrl}]
                } else {
                  collect-outlines ($item.content | default [])
                }
              }
            } | flatten | compact
          }

          let feeds = collect-outlines $bodyChildren

            let sourceEntries = (
              $feeds
              | each {|f|
                let name = ($f.name | str replace --all '"' "")
                let url = ($f.url | str replace --all '"' "")
                $"(char newline)    - name: \"($name)\"(char newline)      rss:(char newline)        url: \"($url)\""
              }
              | str join ""
            )

            let header = $"llms:\n  - name: local-gen\n    default: true\n    provider: openai\n    endpoint: http://127.0.0.1:11434/v1\n    model: qwen3:8b\n    api_key: ollama\n  - name: local-embed\n    provider: openai\n    endpoint: http://127.0.0.1:11434/v1\n    embedding_model: nomic-embed-text\n    api_key: ollama\napi:\n  mcp:\n    address: ':1301'\nscrape:\n  past: 8760h\n  interval: 1h\n  sources:($sourceEntries)\nstorage:\n  feed:\n    retention: 730d\n    embedding_llm: local-embed\n"

            mkdir ($out | path dirname)
            $header | save --force $out
            print $"Config written to ($out) with ($feeds | length) feeds."
        '';

        generateConfig = pkgs.writeShellScript "zenfeed-generate-config" ''
          export OPML_PATH=${lib.escapeShellArg opmlPath}
          export CONFIG_OUT=${lib.escapeShellArg configFile}
          exec ${lib.getExe pkgs.nushell} ${configGenNu}
        '';
      in
      {
        services.ollama = {
          enable = true;
          loadModels = [
            "nomic-embed-text"
            "qwen3:8b"
          ];
        };

        virtualisation.podman = {
          enable = true;
          dockerCompat = true;
        };

        systemd.services.zenfeed-setup = {
          description = "Generate Zenfeed config from OPML on first boot";
          after = [ "network.target" ];
          before = [ "podman-zenfeed.service" ];
          wants = [ "podman-zenfeed.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = generateConfig;
            StateDirectory = "zenfeed";
          };
        };

        virtualisation.oci-containers = {
          backend = "podman";
          containers.zenfeed = {
            image = "ghcr.io/glidea/zenfeed:latest";
            ports = [
              "127.0.0.1:1300:1300"
              "127.0.0.1:1301:1301"
            ];
            volumes = [
              "${dataDir}/data:/app/data"
              "${configDir}:/app/config"
            ];
            environment = {
              TZ = "Asia/Shanghai";
            };
            autoStart = true;
          };
          containers.zenfeed-web = {
            image = "ghcr.io/glidea/zenfeed-web:latest";
            ports = [ "127.0.0.1:1400:1400" ];
            dependsOn = [ "zenfeed" ];
            environment = {
              PUBLIC_DEFAULT_API_URL = "http://zenfeed:1300";
            };
            autoStart = true;
          };
        };

        environment.systemPackages = [
          pkgs.nushell
          pkgs.podman
        ];

        systemd.tmpfiles.rules = [
          "d ${dataDir}/data 0755 root root -"
          "d ${configDir} 0755 root root -"
        ];
      };
  };
}
