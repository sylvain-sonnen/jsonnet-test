chart = prometheus-community/kube-prometheus-stack
version = 55.5.1
name = monitoring

install:
	helm repo add ${name} https://prometheus-community.github.io/helm-charts
	helm install -n ${name} --create-namespace -f values.yaml ${name} ${chart}  --version ${version}

update:
	helm upgrade -n ${name} --install -f values.yaml ${name} ${chart}  --version ${version} --output table
 

uninstall:
	helm uninstall -n ${name} ${name}
