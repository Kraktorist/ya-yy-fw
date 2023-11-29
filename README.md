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

Nodes provisioning works using ansible. Ansible can work through bastion as ssh proxy. Just define the variable ANSIBLE_SSH_COMMON_ARGS

```
export ANSIBLE_SSH_COMMON_ARGS='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@<BASTION_IP> -p 22"'
```

The exact command is added to terraform output as a hint

```bash
user@host:~/$ terraform output -raw ANSIBLE_SSH_COMMON_ARGS
export ANSIBLE_SSH_COMMON_ARGS='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.107.13 -p 22"'
```

if you need ssh
```
ssh -A -J ubuntu@158.160.107.13 ubuntu@cl1och88qht6th1t2bdt-emil.ru-central1.internal
```

### Postgresql

```
ansible-playbook -i terraform/inventory.yaml -u ubuntu ansible/postgresql/playbook.yml
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