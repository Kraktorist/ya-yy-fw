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
- unclear if it uses static port and static logs location**

## Building infrastructure

Infra config is defined as `config.yml`. It includes the following entities:

- tower (jumphost)
- monitoring
- postgresql
- bingo node group

To apply run

```
terraform apply

```

## Nodes provisioning

Nodes provisioning works using ansible. Ansible can work through bastion/jumphost. Just define the variable ANSIBLE_SSH_COMMON_ARGS and copy ssh key to the jumphost

```
export ANSIBLE_SSH_COMMON_ARGS='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@<BASTION_IP> -p 22"'
scp ~/.ssh/id_rsa ubuntu@<BASTION_IP>:./.ssh/
```

### Postgresql

```
ansible-playbook -i terraform/inventory.yaml -u ubuntu ansible/postgresql/playbook.yml
```

**TODO**

- create nginx configuration
- build terraform infrastructure
- deploy application
- build deployment pipeline
- work on public domain
- work on caching
- work on monitoring