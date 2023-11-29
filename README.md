# Final project

## Building the app container

More docs are located [here](./build/README.md).

We've got the following requirements for the app:

- config location /opt/bingo/config.yaml
- logs location /opt/bongo/logs/c863ac3e8e
- port 13526
- run as non-root
- postgres as a database (connections string is needed)
- initial migration is required (seems like it should be run only once to populate the database)

Known issues:

- the app stops in a random way with success or fail exit code. 
- two instances of the app stop in the same moment. 
- the app writes too many logs
- unclear if it uses static port and static logs location
- unclear if it uses evnironment variables

## Building infrastructure

Infra config is defined as `config.yml`. It includes the following entities:

- tower (jumphost)
- monitoring
- postgresql
- bingo node group
- nginx reverse proxy

To apply run

```
TF_VAR_env_folder=$(pwd)/envs/dev terraform -chdir=terraform plan

```

## Nodes provisioning

Nodes provisioning works using ansible. Ansible can work through bastion as ssh proxy which is defined as env variable ANSIBLE_SSH_COMMON_ARGS. Value of this variable is exported as output of terraform and can be exported to the current session with bash `eval` command.

```
eval $(terraform -chdir=terraform output -raw ANSIBLE_SSH_COMMON_ARGS)
```

if you need ssh
```
ssh -A -J <username>@<BASTION_IP> <username>@<target_host>
```

```
ansible-playbook -i envs/dev/inventory.yaml ansible/playbook.yml
```

## Pipeline

- create infrastructure with terraform
  - bingo node groups
  - postgresql host
  - nginx host
- create ansible inventory with terraform
- generate required configs
  - bingo config
  - nginx configuration
- provision hosts
  - postgresql
  - nginx
  - bingo

**TODO**

- create nginx configuration
- deploy application
- build deployment pipeline
- work on public domain
- work on caching
- work on monitoring