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
TF_VAR_env_folder=$(pwd)/envs/dev terraform -chdir=terraform apply

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

### Regarding bingo healthcheck

1. Added `HEALTHCHECK` to [Dockerfile](./build/Dockerfile)
2. Found that docker and docker-compose don't kill unhealthy containers
3. Added `autoheal` service to docker-compose which checks and restarts unhealthy containers

NB: unsuccessfully tried to implement *active* healthcheck which would kill the process inside of container

### Regarding database population

1. Found the key in bingo help `bingo prepare_db`
2. Run it as an ansible task

### Regarding slow queries

1. Added ssd disk for database location (got last 5GB from granted cloud)
2. Reconfigured `shared_buffers` and `work_mem`
3. Added indices on the database

### Regarding /long_dummy

1. Configured cache settings for nginx

### Regarding http3

1. Added domain bingo.qamo.ru
2. Generated tls certificate
3. Enabled https in nginx config
4. configured quic in nginx config

```bash
user@host: fw$ docker run --rm ymuski/curl-http3 curl -kv --http3 https://bingo.qamo.ru/
* processing: https://bingo.qamo.ru/
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 178.154.207.84:443...
* Connected to bingo.qamo.ru (178.154.207.84) port 443
* using HTTP/3
* Using HTTP/3 Stream ID: 0
> GET / HTTP/3
> Host: bingo.qamo.ru
> User-Agent: curl/8.2.1-DEV
> Accept: */*
> 
< HTTP/3 200 
< server: nginx/1.25.3
< date: Wed, 29 Nov 2023 22:24:44 GMT
< content-type: text/plain; charset=utf-8
< content-length: 336
< alt-svc: h3=":443"; ma=86400
< 
{ [336 bytes data]
100   336  100   336    0     0   9500      0 --:--:-- --:--:-- --:--:--  9600
* Connection #0 to host bingo.qamo.ru left intact
Hi. Accept my congratulations. You were able to launch this app.
In the text of the task, you were given a list of urls and requirements for their work.
Get on with it. You can do it, you'll do it.
--------------------------------------------------
code:         ******************
--------------------------------------------------

```

tail -f /var/log/nginx/access.log
```
xxx.xx.xx.xxx - - [29/Nov/2023:22:24:44 +0000] "GET / HTTP/3.0" 200 336 "-" "curl/8.2.1-DEV" "-"
```


**TODO**


- add env variable to ansible
- build deployment pipeline
- work on monitoring
