kubectl create -f logging.yaml
kubectl create -f elasticsearch_svc.yaml
kubectl create -f elasticsearch_statefulset.yaml
kubectl create -f kibana.yaml
kubectl create -f fluentd.yaml

#apply port forwarding to make kibana available on localhoast 5601
#apply some grep command to find the name of the kibana cluster
#kubectl port-forward  5601:5601 --namespace=kube-logging
