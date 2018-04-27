# How to Configure Access to Docker Registry

You need a server cert, e.g., blade1.se.internal.crt

Create directory for certs
# mkdir -p /etc/docker/certs.d/

Create directory for a specific domain with

# mkdir -p /etc/docker/certs.d/$DOMAIN

For blade1.se.internal this is

# mkdir -p /etc/docker/certs.d/blade1.se.internal:5000

Note the port number is included in the directory name

Copy the cert to the directory
# cp blade1.se.internal.crt /etc/docker/certs.d/blade1.se.internal:5000/ca.crt

Restart docker
# service docker restart


