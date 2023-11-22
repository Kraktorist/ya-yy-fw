## Requirements

- postgres
- two nodes - workers
- docker
- load balancer
- caching system*
- monitoring*
- devops*

### Postgresql

Managed service deployed with terraform

### Workers

ec2 instances deployed from an instance template (see 1 min for deployment requirement)

### docker

should be preinstalled to the instance template?

### Load balancer

Options:

- NLB?
- ALB?

### Caching system

seems like the easiest option is to use nginx/haproxy as a reverse proxy and balancer with caching. 

- How to implement distributed cache?
- Overkill? https://dev.to/satrobit/how-to-set-up-an-nginx-reverse-proxy-cluster-with-a-shared-cache-38eh

## Deployment configuration

1. It's a yaml file or files.