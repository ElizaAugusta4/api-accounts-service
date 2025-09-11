#!/bin/bash
set -euo pipefail

# Instala kubectl se não existir
if ! command -v kubectl &> /dev/null; then
  echo "Instalando kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Instala kind se não existir
if ! command -v kind &> /dev/null; then
  echo "Instalando kind..."
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
fi


# Garante permissão para usar Docker
sudo usermod -aG docker $USER
newgrp docker

# Cria cluster local com kind
echo "===> Criando cluster local com Kind..."
sudo kind create cluster --name prod-finance --wait 60s

# Configura KUBECONFIG
echo "===> Configurando KUBECONFIG..."
if [ -z "${KUBECONFIG:-}" ]; then
  if [ -z "${KUBE_CONFIG_DATA:-}" ]; then
    export KUBECONFIG="$(kind get kubeconfig-path --name=\"ci-cluster\" 2>/dev/null || echo \"\")"
    if [ -z \"$KUBECONFIG\" ]; then
      echo \"❌ ERRO: KUBE_CONFIG_DATA não definido e KUBECONFIG não encontrado!\"
      exit 1
    fi
  else
    echo \"$KUBE_CONFIG_DATA\" | base64 --decode > kubeconfig
    export KUBECONFIG=$(pwd)/kubeconfig
  fi
fi

# Aplica os manifests
echo \"===> Aplicando manifests do diretório K8s-manifests/...\"
kubectl apply -f K8s-manifests/

# Aguarda rollout dos deployments
echo \"===> Aguardando rollout dos deployments...\"
for DEPLOY in accounts-service transactions-service balance-service; do
  echo \"----> Validando $DEPLOY\"
  kubectl rollout status deployment/$DEPLOY --timeout=120s
done

# Health check dos serviços
echo \"===> Fazendo health check dos serviços...\"
for SVC in accounts-service transactions-service balance-service; do
  CLUSTER_IP=$(kubectl get svc $SVC -o jsonpath='{.spec.clusterIP}')
  PORT=$(kubectl get svc $SVC -o jsonpath='{.spec.ports[0].port}')
  echo \"----> $SVC acessível em $CLUSTER_IP:$PORT (dentro do cluster)\"
done

echo \"✅ Deploy finalizado com sucesso!\"