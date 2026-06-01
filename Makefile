CLUSTER_NAME=magento-local

create:
	kind create cluster \
		--name $(CLUSTER_NAME) \
		--config kind/cluster.yaml

install-ingress:
	kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

	kubectl wait \
		--namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=300s

create-cluster: create install-ingress

delete-cluster:
	kind delete cluster --name $(CLUSTER_NAME)

nodes:
	kubectl get nodes -o wide

pods:
	kubectl get pods -A -o wide

events:
	kubectl get events -A --sort-by=.metadata.creationTimestamp

prepare-magento-infra:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/mysql/mysql-config.yaml
	kubectl apply -f k8s/mysql/mysql-secret.yaml
	kubectl apply -f k8s/mysql/mysql-service.yaml
	kubectl apply -f k8s/mysql/mysql-statefulset.yaml
	kubectl apply -f k8s/redis/redis-service.yaml
	kubectl apply -f k8s/redis/redis-statefulset.yaml
	kubectl apply -f k8s/opensearch/opensearch-service.yaml
	kubectl apply -f k8s/opensearch/opensearch-statefulset.yaml

insert-magento-url-hosts:
	grep -qxF "127.0.0.1 magento.local" /etc/hosts || echo "127.0.0.1 magento.local" | sudo tee -a /etc/hosts

install-magento:
	helm install magento ./helm/magento -n magento

update-magento:
	helm upgrade --install magento ./helm/magento -n magento

install-magento-logs:
	kubectl logs -f deployment/magento -n magento

uninstall-magento:
	helm uninstall magento -n magento

see-pods:
	kubectl get pods -n magento

delete-magento-pods:
	kubectl delete pod -n magento -l app=magento