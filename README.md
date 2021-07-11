# docker-bind9-secondary
Docker images to create secondary bind server


Environment variables

LISTEN_ON
* any;
* 192.168.1.1:53;

ALLOW_QUERY
* any;
* 192.168.0.0/24;192.168.1.0/24;

QUERYLOG
* no;
* yes;

SECONDARY_ZONES

format:

zonename,masterlist[|zonename,masterlist|....]

examples:

mydomain.com,192.168.0.1;192.168.1.1;|0.168.192.in-addr.arpa,192.168.0.1;192.168.1.1;

KEYS

format:

server,keyname,algorithm,key[|server,keyname,algorithm,key|....]

example:

192.168.0.1,mykey,hmac-md5,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|192.168.1.1,mykey,hmac-md5,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

RECURSION

* any;
* 192.168.0.0/24;192.168.1.0/24;

FORWARDERS

* 8.8.8.8;8.8.4.4;



```bash
docker run --rm -it --env "SECONDARY_ZONES=mydomain.com,192.168.0.1;192.168.1.1;|0.168.192.in-addr.arpa,192.168.0.1;192.168.1.1;" --env "KEYS=192.168.0.1,mykey,hmac-md5,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|192.168.1.1,mykey,hmac-md5,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" --publish 54:53/tcp --publish 54:53/udp aiur/bind9-slave:0.2
```