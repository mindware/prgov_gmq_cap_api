# Do basic actions on every restart on development
system("killall ruby; killall beanstalkd; foreman start;")
