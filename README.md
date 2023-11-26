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

**TODO**

- create nginx configuration
- build terraform infrastructure
- deploy postgresql
- deploy application
- build deployment pipeline
- work on public domain
- work on caching
- work on monitoring