chart = argocd/argo-cd 
version = 6.0.14
name = argocd

install:
	helm install -n ${name} --create-namespace -f values.yaml ${name} ${chart}  --version ${version}

update:
	helm upgrade -n ${name} --install -f values.yaml ${name} ${chart}  --version ${version} --output table
 

uninstall:
	helm uninstall -n ${name} ${name}


