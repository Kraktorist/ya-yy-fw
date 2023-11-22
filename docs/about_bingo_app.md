## config location

```
strace -e openat ./binary/bingo print_current_config
openat(AT_FDCWD, "/sys/kernel/mm/transparent_hugepage/hpage_pmd_size", O_RDONLY) = 3
openat(AT_FDCWD, "/opt/bingo/config.yaml", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
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

