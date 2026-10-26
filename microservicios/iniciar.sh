#!/bin/bash
set -e

echo "=== 1. Verificando estado de Minikube ==="
minikube status >/dev/null 2>&1 || minikube start --driver=docker

echo "=== 2. Configurando Namespace y Secret ==="
kubectl create namespace microservicios --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic db-credentials \
  --from-literal=usuarios-user=usuarios_user \
  --from-literal=usuarios-password=usuarios123 \
  --from-literal=productos-user=productos_user \
  --from-literal=productos-password=productos123 \
  --from-literal=pedidos-user=pedidos_user \
  --from-literal=pedidos-password=pedidos123 \
  -n microservicios --dry-run=client -o yaml | kubectl apply -f -

echo "=== 3. Cargando ConfigMaps de inicialización ==="
kubectl create configmap usuarios-init --from-file=$HOME/proyecto-monolito-microservicios/microservicios/usuarios/init.sql -n microservicios --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap productos-init --from-file=$HOME/proyecto-monolito-microservicios/microservicios/productos/init.sql -n microservicios --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap pedidos-init --from-file=$HOME/proyecto-monolito-microservicios/microservicios/pedidos/init.sql -n microservicios --dry-run=client -o yaml | kubectl apply -f -

echo "=== 4. Desplegando Bases de Datos y Microservicios ==="
kubectl apply -f k8s/bases-datos.yaml
kubectl apply -f k8s/microservicios.yaml

echo "=== 5. Esperando a que todos los Pods estén en Ready ==="
kubectl wait --for=condition=ready pod --all -n microservicios --timeout=120s

echo "=== 6. Estado final del Clúster ==="
kubectl get pods,svc -n microservicios

echo "=== ¡Despliegue y validación completados correctamente! ==="
