{ config, pkgs, ... }:
{
  packages = with pkgs; [
    pass
    jq
    terraform
    awscli2
  ];

  env = {
    AWS_PROFILE                = "mhemeryck";
    TF_VAR_do_token            = config.secretspec.secrets.DIGITALOCEAN_TOKEN;
    TF_VAR_hcloud_token        = config.secretspec.secrets.HCLOUD_TOKEN;
  };

  enterShell = ''
    kubeconfig_source="$(secretspec get KUBECONFIG)"
    install -m 600 "$kubeconfig_source" "$DEVENV_RUNTIME/kubeconfig"
    rm -f "$kubeconfig_source"
    export KUBECONFIG="$DEVENV_RUNTIME/kubeconfig"
  '';
}
