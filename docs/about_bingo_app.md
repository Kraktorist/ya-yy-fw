## config and log location

```
strace -e openat ./binary/bingo run_server
openat(AT_FDCWD, "/sys/kernel/mm/transparent_hugepage/hpage_pmd_size", O_RDONLY) = 3
openat(AT_FDCWD, "/opt/bingo/config.yaml", O_RDONLY|O_CLOEXEC) = 6
openat(AT_FDCWD, "/opt/bongo/logs/c863ac3e8e/main.log", O_WRONLY|O_CREAT|O_APPEND|O_CLOEXEC, 0666) = -1 ENOENT (No such file or directory)

```

## Ports

```
~ $ netstat -tunlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 127.0.0.11:42017        0.0.0.0:*               LISTEN      -
tcp        0      0 :::13526                :::*                    LISTEN      1/bingo
udp        0      0 127.0.0.11:39793        0.0.0.0:*                           -

```

## Configuration parameters

```
./binary/bingo print_default_config  
```

```yaml
student_email: test@example.com
postgres_cluster:
  hosts:
  - address: localhost
    port: 5432
  user: postgres
  password: postgres
  db_name: postgres
  ssl_mode: disable
  use_closest_node: false
```

### Questions

How to get if the app reads specific ENV variables?

