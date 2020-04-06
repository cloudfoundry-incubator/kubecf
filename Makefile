minikube-start:
	@./scripts/minikube-start.sh

minikube-delete:
	@./scripts/minikube-delete.sh

cf-operator-apply:
	@./scripts/cf-operator-apply.sh

kubecf-build:
	@./scripts/kubecf-build.sh

kubecf-apply:
	@./scripts/kubecf-apply.sh

kubecf-delete:
	@./scripts/kubecf-delete.sh

testing-smoke:
	@./scripts/testing-smoke.sh

tools-install:
	@./scripts/tools-install.sh

tools-versions:
	@./scripts/tools-versions.sh
