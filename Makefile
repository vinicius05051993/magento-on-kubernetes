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

create-external-infra:
	docker compose -f docker/external-infra/docker-compose.yml up -d

delete-external-infra:
	docker compose -f docker/external-infra/docker-compose.yml down

create-cluster: create install-ingress

delete-cluster:
	kind delete cluster --name $(CLUSTER_NAME)

prepare-magento-infra:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/redis/redis-service.yaml
	kubectl apply -f k8s/redis/redis-statefulset.yaml
	kubectl apply -f k8s/opensearch/opensearch-service.yaml
	kubectl apply -f k8s/opensearch/opensearch-statefulset.yaml
	kubectl apply -f k8s/nfs/magento-media-pv.yaml
	kubectl apply -f k8s/nfs/magento-media-pvc.yaml

insert-magento-url-hosts:
	grep -qxF "127.0.0.1 magento.local" /etc/hosts || echo "127.0.0.1 magento.local" | sudo tee -a /etc/hosts

install-magento:
	helm upgrade --install magento ./helm/magento -n magento

install-magento-logs:
	kubectl logs -f -n magento \
	$$(kubectl get pod -n magento -l app=magento -o jsonpath='{.items[0].metadata.name}') \
	-c magento-install

uninstall-magento:
	helm uninstall magento -n magento

see-pods:
	kubectl get pods -n magento

delete-magento-pods:
	kubectl delete pod -n magento -l app=magento