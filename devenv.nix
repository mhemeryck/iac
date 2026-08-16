{ pkgs, ... }:
{
  packages = with pkgs; [
    pass
    jq
  ];

  enterShell = ''
    export TF_VAR_do_token="$(pass show home/digitalocean_token)"
    export TF_VAR_hcloud_token="$(pass show hcloud_token)"
  '';
}
