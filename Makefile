cf-login:
	@./scripts/cf-login.sh

cf-operator-apply:
	@./scripts/cf-operator-apply.sh

kubecf-apply:
	@./scripts/kubecf-build.sh
	@./scripts/kubecf-apply.sh

kubecf-build:
	@./scripts/kubecf-build.sh

kubecf-delete:
	@./scripts/kubecf-delete.sh

minikube-start:
	@./scripts/minikube-start.sh

minikube-delete:
	@./scripts/minikube-delete.sh

testing-smoke:
	@./scripts/testing-smoke.sh

tools-install:
	@./scripts/tools-install.sh

tools-versions:
	@./scripts/tools-versions.sh

shellcheck:
	@./scripts/shellcheck.sh
