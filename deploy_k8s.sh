#!/bin/bash
set -e

# Instala kubectl se não existir
if ! command -v kubectl &> /dev/null; then
  echo "Instalando kubectl..."
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
fi

# Configura kubeconfig
if [ -z "$KUBE_CONFIG_DATA" ]; then
  echo "KUBE_CONFIG_DATA não definido!"
  exit 1
fi

echo "$KUBE_CONFIG_DATA" | base64 --decode > kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Aplica todos os manifests do diretório k8s
kubectl apply -f K8s-manifests/

# Valida rollout dos deployments
for DEPLOY in accounts-service transactions-service balance-service; do
  kubectl rollout status deployment/$DEPLOY
done

# Aguarda alguns segundos para os serviços subirem
sleep 10

# Faz health check em cada serviço
for SVC in accounts-service transactions-service balance-service; do
  APP_SERVICE=$(kubectl get svc $SVC -o jsonpath='{.spec.clusterIP}')
  APP_PORT=$(kubectl get svc $SVC -o jsonpath='{.spec.ports[0].port}')
  echo "Health check: $SVC"
  curl --fail http://$APP_SERVICE:$APP_PORT/health || {
    echo "Health check falhou para $SVC!"
    exit 1
  }
done

echo "Deploy validado com sucesso para todos os serviços!"