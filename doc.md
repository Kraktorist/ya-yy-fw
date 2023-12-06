# Final project

## Bingo Application

We've got the following requirements for the app:

- config location /opt/bingo/config.yaml
- logs location /opt/bongo/logs/c863ac3e8e
- port 13526
- run as non-root
- postgres as a database (connections string is needed)
- initial migration is required (seems like it should be run only once to populate the database)
- healthcheck endpoint `/ping`

---

<details>
<summary>How to get these parameters</summary>

### Parameters

```
> ./binary/bingo help    
bingo

Usage:
   [flags]
   [command]

Available Commands:
  completion           Generate the autocompletion script for the specified shell
  help                 Help about any command
  prepare_db           prepare_db
  print_current_config print_current_config
  print_default_config print_default_config
  run_server           run_server
  version              version

Flags:
  -h, --help   help for this command

Use " [command] --help" for more information about a command.

```

### Config location
```
>strace -e openat ./binary/bingo print_current_config
openat(AT_FDCWD, "/sys/kernel/mm/transparent_hugepage/hpage_pmd_size", O_RDONLY) = 3
openat(AT_FDCWD, "/opt/bingo/config.yaml", O_RDONLY|O_CLOEXEC) = 6
```
### Logs location
```
strace -e openat ./binary/bingo run_server          
openat(AT_FDCWD, "/sys/kernel/mm/transparent_hugepage/hpage_pmd_size", O_RDONLY) = 3
--- SIGURG {si_signo=SIGURG, si_code=SI_TKILL, si_pid=32075, si_uid=1000} ---
openat(AT_FDCWD, "/opt/bingo/config.yaml", O_RDONLY|O_CLOEXEC) = 6
openat(AT_FDCWD, "/opt/bongo/logs/c863ac3e8e/main.log", O_WRONLY|O_CREAT|O_APPEND|O_CLOEXEC, 0666) = -1 ENOENT (No such file or directory)
```

### Port bind

```
~ $ netstat -tunlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 127.0.0.11:42017        0.0.0.0:*               LISTEN      -
tcp        0      0 :::13526                :::*                    LISTEN      1/bingo
udp        0      0 127.0.0.11:39793        0.0.0.0:*                           -

```

### Non-root user

```
# ./binary/bingo print_current_config
Didn't your mom teach you not to run anything incomprehensible from root?
```

</details>

---

### Building container

Known issues:

- the app stops in a random way with success or fail exit code. 
- two instances of the app stop in the same moment. 
- the app writes too many logs
- seems like it uses static port and static logs location
- unclear if it uses evnironment variables

The following Dockerfile has been created:

- [Dockerfile](./build/Dockerfile) 
- [How to run](./build/README.md).
- [docker-compose](./build/docker-compose.yml) for local tests

---

## Environments

Environments are placed in the folder [envs](./envs/). There are two similar environments `dev` and `prod` in this repo. Just to prove that automated deploy works.

## Building infrastructure

Infrastructure described in`config.yaml` of every environment.

- [envs/dev/config.yaml](./envs/dev/config.yaml)
- [envs/prod/config.yaml](./envs/prod/config.yaml)

It includes multiple hosts:

- bastion (jumphost)
- monitoring
- postgresql
- bingo node group
- nginx reverse proxy

To deploy it

1. Configure `yc`, install `awscli`.
2. Run the command:

```
./install.sh apply dev # this will install dev environment
```

For destroying environment use
```
./install.sh destroy dev # this will install dev environment
```


## Nodes provisioning

Nodes provisioning works using ansible. Provisioning variables are located in `group_vars` folder.Ansible works through bastion as ssh proxy. 

### postgresql provisioning

- copy bingo config
- install postgresql with ansible
- create bingo database
- add some indices

### nginx provisioning

- create nginx cache dir
- upload tls certificates
- install nginx
- generate and upload nginx config for bingo
- restart bingo containers

### bingo provisioning

The app placed in docker image and run as docker-compose on Yandex COI nodes which are installed by terraform. Bingo configs are delivered later by ansible.

- [docker-compose](./build/docker-compose.yml)

### bingo healthcheck

1. Added `HEALTHCHECK` to [Dockerfile](./build/Dockerfile)
2. Found that docker and docker-compose don't kill unhealthy containers
3. Added `autoheal` service to docker-compose which checks and restarts unhealthy containers

NB: unsuccessfully tried to implement *active* healthcheck which would kill the process inside of container

### database population

1. Found the key in bingo help `bingo prepare_db`
2. Run it as an ansible task

### slow queries /api/session

This endpoint requests 100k rows joined from all the tables and by default it takes more than 30s to complete it.

<details>
<summary>slow query</summary>

```
SELECT 
    sessions.id, 
    sessions.start_time, 
    customers.id, 
    customers.name, 
    customers.surname, 
    customers.birthday, 
    customers.email, 
    movies.id, 
    movies.name, 
    movies.year, 
    movies.duration 
FROM sessions 
    INNER JOIN customers ON sessions.customer_id = customers.id 
    INNER JOIN movies ON sessions.movie_id = movies.id 
ORDER BY movies.year DESC, 
         movies.name ASC, 
         customers.id, 
         sessions.id DESC 
LIMIT 100000;

```
</details>

The following actions have been done to improve its performance^

1. Added ssd disk for database location (got last 5GB from granted cloud)
2. Reconfigured `shared_buffers` and `work_mem`
3. Added indices on the database

### /long_dummy

1. Configured cache settings for nginx

### http3

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

- deploy and provisioning postgresql, generate bingo configuration file
- deploy bingo instance group
- provision instance group
  - docker-compose
  - ssh-keys
  - copy bingo configuration file (mount.nfs + cp bingo conf)



