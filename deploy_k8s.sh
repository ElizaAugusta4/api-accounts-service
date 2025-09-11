#!/bin/bash
set -euo pipefail

echo "===> Configurando KUBECONFIG..."
if [ -z "${KUBECONFIG:-}" ]; then
  if [ -z "${KUBE_CONFIG_DATA:-}" ]; then
    echo "❌ ERRO: KUBE_CONFIG_DATA não definido!"
    exit 1
  fi
  echo "$KUBE_CONFIG_DATA" | base64 --decode > kubeconfig
  export KUBECONFIG=$(pwd)/kubeconfig
fi

echo "===> Aplicando manifests do diretório K8s-manifests/..."
kubectl apply -f K8s-manifests/

echo "===> Aguardando rollout dos deployments..."
for DEPLOY in accounts-service transactions-service balance-service; do
  echo "----> Validando $DEPLOY"
  kubectl rollout status deployment/$DEPLOY --timeout=120s
done

echo "===> Fazendo health check dos serviços..."
for SVC in accounts-service transactions-service balance-service; do
  CLUSTER_IP=$(kubectl get svc $SVC -o jsonpath='{.spec.clusterIP}')
  PORT=$(kubectl get svc $SVC -o jsonpath='{.spec.ports[0].port}')
  echo "----> $SVC acessível em $CLUSTER_IP:$PORT (dentro do cluster)"
done

echo "✅ Deploy finalizado com sucesso!"
