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

services:
	kubectl get svc -A

ingress:
	kubectl get ingress -A

events:
	kubectl get events -A --sort-by=.metadata.creationTimestamp

docker-nodes:
	docker ps

cluster-info:
	kubectl cluster-info

shell-control-plane:
	docker exec -it $(CLUSTER_NAME)-control-plane bash

shell-worker:
	docker exec -it $(CLUSTER_NAME)-worker bash

build-load-php-image:
	docker buildx build --no-cache --platform linux/amd64 --build-arg MAGENTO_PUBLIC_KEY=ee65270ec48a5d928415e00dfbd7898a --build-arg MAGENTO_PRIVATE_KEY=112b4ccfee3e8b317204f03f63121bbe -t magento-php:2.4.9-php8.3 -f docker/php/Dockerfile --load .
	kind load docker-image magento-php:2.4.9-php8.3 --name magento-local

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

install-magento-logs:
	kubectl logs -f job/magento-install -n magento

uninstall-magento:
	helm uninstall magento -n magento

see-pods:
	kubectl get pods -n magento

delete-magento-pods:
	kubectl delete pod -n magento -l app=magento

delete-job-magento-installation:
	kubectl delete job magento-install -n magento