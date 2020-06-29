# Infrastructure as code

terraform setup for personal projects

## terraform

	export TF_VAR_do_token=`bat kube_key.pub`
	terraform plan
	terraform apply

## provision

	k3sup install --ip $(terraform output ip) --user root --ssh-key=kube_key --local-path=./kubeconfig
