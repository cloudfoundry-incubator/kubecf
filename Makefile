
# Destroys your kind cluster completely.
kinddown:
	bazel run //dev/kind:delete

# Creates a new kind cluster for you.
kindup:
	bazel run //dev/kind:start

# Lists all bazel targets, so you can grep for what you need.
bazel-targets:
	bazel query 'attr(visibility, "//visibility:public", ...)' && \
	bazel query 'attr(visibility, "", ...)'

# Installs/updates KubeCF (on whatever cluster your kubectl points to).
apply:
	bazel run //dev/kubecf:apply

# Installs the CF operator.
# TODO: this should be done with bazel.
operatorup:
	k create namespace cf-operator && \
	bazel run //dev/cf_operator:apply

# Cleans everything up but doesn't destroy your cluster.
# TODO: this should be done with bazel.
clean:
	bazel run //dev/kubecf:delete ; \
	bazel run //dev/cf_operator:delete ; \
	helm delete kubecf ; \
	helm delete cf-operator ; \
	k delete namespace kubecf ; \
	k delete namespace cf-operator ; \
	k delete clusterrole cf-operator-quarks-job ; \
	k delete clusterrole cf-operator ; \
	k delete crd boshdeployments.quarks.cloudfoundry.org ; \
	k delete crd quarksjobs.quarks.cloudfoundry.org ; \
	k delete crd quarkssecrets.quarks.cloudfoundry.org ; \
	k delete crd quarksstatefulsets.quarks.cloudfoundry.org ; \
	k delete clusterrolebinding cf-operator-quarks-job ; \
	k delete clusterrolebinding cf-operator ; \
	k delete psp kubecf-default

