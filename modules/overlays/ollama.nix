{
  flake.overlays.ollama = final: prev: {
    ollama = prev.ollama.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0.20.1";
      src = prev.fetchFromGitHub {
        owner = "ollama";
        repo = "ollama";
        tag = "v0.20.1";
        hash = "sha256-CfDoP1UJF8vl3CkLg8diwQjtEwDClR4DXc2hXLdm1bo=";
      };
      vendorHash = "sha256-Lc1Ktdqtv2VhJQssk8K1UOimeEjVNvDWePE9WkamCos=";
    });
  };
}
