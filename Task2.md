2.1 
depends_on - container dependencies on other containers in the compose specification
environment - defines environment variables
volumes -  defines which volumes the container uses  
command - runs the container with this command

For redis:
redis-server --save 60 1 --loglevel warning

2.2 

Configure .env

Use ${variable}