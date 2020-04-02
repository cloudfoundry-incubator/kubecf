
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
	bazel run @kubectl//:binary -- create namespace cf-operator && \
	bazel run //dev/cf_operator:apply

# Cleans everything up but doesn't destroy your cluster.
# TODO: this should be done with bazel.
clean:
	bazel run //dev/kubecf:delete ; \
	bazel run //dev/cf_operator:delete ; \
	bazel run @helm//:binary -- delete kubecf ; \
	bazel run @helm//:binary -- delete cf-operator ; \
	bazel run @kubectl//:binary -- delete namespace kubecf ; \
	bazel run @kubectl//:binary -- delete namespace cf-operator ; \
	bazel run @kubectl//:binary -- delete clusterrole cf-operator-quarks-job ; \
	bazel run @kubectl//:binary -- delete clusterrole cf-operator ; \
	bazel run @kubectl//:binary -- delete crd boshdeployments.quarks.cloudfoundry.org ; \
	bazel run @kubectl//:binary -- delete crd quarksjobs.quarks.cloudfoundry.org ; \
	bazel run @kubectl//:binary -- delete crd quarkssecrets.quarks.cloudfoundry.org ; \
	bazel run @kubectl//:binary -- delete crd quarksstatefulsets.quarks.cloudfoundry.org ; \
	bazel run @kubectl//:binary -- delete clusterrolebinding cf-operator-quarks-job ; \
	bazel run @kubectl//:binary -- delete clusterrolebinding cf-operator ; \
	bazel run @kubectl//:binary -- delete psp kubecf-default
