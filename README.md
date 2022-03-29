# Docker bind9-secondary
Docker image to create secondary bind server


## Environment variables

| Variable | Value | Default | Description |
| -------- | ----- | ------- | ----------- |
| `ALLOW_QUERY` | address_match_element; ... | any; | allow-query { \<value\> };
| `FORWARDERS` | ( ipv4_address \| ipv6_address ) [ port integer ]; ... | | forwarders { \<value\> };<br>forward only;
| `KEYS` | server,name,algo,secret[\|...] | | key \<name\> { algorithm \<algo\>; secret \<secret\>; };<br>server \<server\> { keys \<name\>; };
| `LISTEN_ON` | address_match_element; ... | any; | listen-on { \<value\> };<br>listen-on-v6 { none; };
| `QUERYLOG` | boolean; | no; | querylog \<value\>
| `RECURSION` | address_match_element; ... | none; | recursion yes;<br>allow-recursion { \<value\> };
| `SECONDARY_ZONES` | zone,primary[\|...] | | zone \<zone\> { type slave; masters { \<primary\> }; file "/var/bind/sec/\<zone\>"; };


## Examples

### Docker

```bash
docker run --rm -it --env "SECONDARY_ZONES=mydomain.com,192.168.0.1;192.168.1.1;|0.168.192.in-addr.arpa,192.168.0.1;192.168.1.1;" --env "KEYS=192.168.0.1,mykey,hmac-md5,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|192.168.1.1,mykey,hmac-md5,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" --publish 53:53/tcp --publish 53:53/udp daisaacson/bind9-secondary
```

### Kubernetes

Generate the secret
```bash
echo -n "192.168.0.1,master,hmac-sha256,R3HI8P6BKw9ZwXwN3VZKuQ==" | base64 -w0
```

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: bind9-secondary-configmap
data:
  zones: "mydomain.com,192.168.0.1;|0.168.192.in-addr.arpa,192.168.0.1;"
---
apiVersion: v1
kind: Secret
metadata:
  name: bind9-secondary-secret
type: Opaque
data:
  bind9-secondary-keys: MTkyLjE2OC4wLjEsbWFzdGVyLGhtYWMtc2hhMjU2LFIzSEk4UDZCS3c5WndYd04zVlpLdVE9PQ==
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bind9-secondary
spec:
  selector:
    matchLabels:
      app: bind9-secondary
  template:
    metadata:
      labels:
        app: bind9-secondary
    spec:
      containers:
      - name: bind9-secondary
        image: daisaacson/bind9-secondary:0.4
        env:
        - name: SECONDARY_ZONES
          valueFrom:
            configMapKeyRef:
              name: bind9-secondary-configmap
              key: zones
        - name: KEYS
          valueFrom:
            secretKeyRef:
              name: bind9-secondary-secret
              key: bind9-secondary-keys
        resources:
          limits:
            memory: "105Mi"
            cpu: "12m"
          requests:
            memory: "35Mi"
            cpu: "4m"
        ports:
        - containerPort: 53
          protocol: TCP
        - containerPort: 53
          protocol: UDP

```
