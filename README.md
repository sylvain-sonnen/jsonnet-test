# Grafana IaC experiments

## Start a quick k8s cluster 

(requires a container engine, I use [podman desktop because macos](https://podman-desktop.io/),  and [kind](https://kind.sigs.k8s.io/)

then you can run:
```bash
kind create cluster --config ./kind/kindConfig.yaml
```
## Start kube prom stack

```bash
cd ./helm/monitoring
make install
```

## To start ArgoCD with Tanka plugin enabled

```bash
cd ./helm/argocd/
kubectl apply -f ./development/config-managment-plugin.yaml
make install
```
