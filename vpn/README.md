## Usage

1) Install vireguard
2) copy dev-vpn.conf to /etc/wireguard/
```
sudo cp dev-vpn.conf /etc/wireguard/dev-vpn.conf
```
3) For connect to vpn use
```
sudo wg-quick up dev-vpn
```
4) Check http://admin-web-service.webdevelop-dev.svc.cluster.local:8085/admin
5) For disconnect vpn use
```
sudo wg-quick down dev-vpn
```

## Dirrect access to services via vpn network

For connect to some service, use this format for urls:

```
http://<service_namme>-service.webdevelop-dev.svc.cluster.local:8085/***
```

all service names you can find here: https://github.com/webdevelop-pro/devops/tree/master/configs/global/webdevelop

## Diagram 

![image](https://github.com/webdevelop-pro/gcp-devops/assets/10445445/0b2397b1-f387-4bd1-b769-8dc03b93b09d)
