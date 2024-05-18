## Usage

1) Install vireguard
2) copy dev-vpn.conf to /etc/wireguard/ (or ask somebody to give your personal vpn config)
```
sudo cp dev-vpn.conf /etc/wireguard/dev-vpn.conf
```
3) Add hosts from hosts file to your /etc/hosts
```
sudo sh -c 'cat hosts >> /etc/hosts'
```
4) For connect to vpn use
```
sudo wg-quick up dev-vpn
```
5) Check http://admin-web-service.webdevelop-dev.svc.cluster.local:8085/admin
6) For disconnect vpn use
```
sudo wg-quick down dev-vpn
```

## Dirrect access to services via vpn network

For connect to some service, use this format for urls:

```
http://<service_namme>-service.webdevelop-dev.svc.cluster.local:8085/***
```

- all service names you can find here: https://github.com/webdevelop-pro/devops/tree/master/configs/global/webdevelop
- for pass authorization you can add `Authoriztion: <identity_id>` header

## Get personal vpn peer config

Execute:

```
./get_peer_conf.sh <PEER_NUM>
```

Where PEER_NUM is your peer number 2-6

P.S. If your need peers > 6 you can increase PEERS var in  https://github.com/webdevelop-pro/gcp-devops/blob/master/vpn/wireguard-k8s.yaml#L31 and run:

```
kubectl apply -f wireguard-k8s.yaml 
```

## Diagram 

![image](https://github.com/webdevelop-pro/gcp-devops/assets/10445445/0b2397b1-f387-4bd1-b769-8dc03b93b09d)
