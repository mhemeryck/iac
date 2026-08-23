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
    TF_VAR_billing_alert_email = config.secretspec.secrets.BILLING_ALERT_EMAIL;
    TF_VAR_do_token            = config.secretspec.secrets.DIGITALOCEAN_TOKEN;
    TF_VAR_hcloud_token        = config.secretspec.secrets.HCLOUD_TOKEN;
  };
}
