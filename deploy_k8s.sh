#!/bin/bash

# Instala Docker
if ! command -v docker &> /dev/null; then
  echo "Instalando Docker..."
  sudo yum install -y docker
  sudo systemctl start docker
  sudo systemctl enable docker
fi

# Instala kubeadm, kubelet e kubectl
if ! command -v kubeadm &> /dev/null; then
  echo "Configurando repositório Kubernetes..."
  cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
  sudo setenforce 0 || true
  sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
  sudo systemctl enable kubelet
  sudo systemctl start kubelet
fi

# Inicializa o cluster Kubernetes
if [ ! -f /etc/kubernetes/admin.conf ]; then
  echo "Inicializando cluster Kubernetes..."
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16 || true
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
fi
export KUBECONFIG=$HOME/.kube/config

# Instala rede Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml || true

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

  # Instala kubectl se não existir
  if ! command -v kubectl &> /dev/null; then
    echo "Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
  fi

  # Configura kubeconfig
  if [ -z "$KUBE_CONFIG_DATA" ]; then
    echo "KUBE_CONFIG_DATA não definido!"
    exit 1
  fi

  echo "$KUBE_CONFIG_DATA" | base64 --decode > kubeconfig
  export KUBECONFIG=$(pwd)/kubeconfig
