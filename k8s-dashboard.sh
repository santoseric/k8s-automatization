#!/bin/bash

# See: https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard

# Dedicate a namespace for the Kubernetes dashboard, "kubernetes-dashboard" trends to be current standard
kubectl create namespace kubernetes-dashboard

# Add an admin-user service account to grant the Dashboard the roles to access cluster resources and objects.
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

## Set dashboard Helm chart values for this context, metrics server enabled for richer content
cat << 'EOF' > /opt/dash-values.yaml
protocolHttp: true

extraArgs:
  - --enable-insecure-login

metricsScraper:
  enabled: true

metrics-server:
  enabled: true
  args:
    - --kubelet-preferred-address-types=InternalIP
    - --kubelet-insecure-tls

service:
  type: NodePort
  nodePort: 30000
  externalPort: 80
EOF

# Check for old version of Helm in some instances (when running on katacoda.com), need helm install --create-namespace
helm version --short | grep '3.1.2'
if [ $? -eq 0 ]
then
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

# Add Helm chart repo
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

# Latest tested Helm chart, update this version regularly
K8S_DASH_HELM_CHART_VERSION=5.4.1

# For K8s version <1.19
kubectl version --short | grep 1.18.0
if [ $? -eq 0 ]
then 
  K8S_DASH_HELM_CHART_VERSION=3.0.2 
fi

# Install the Kubernetes dashboard
echo "Installing chart version $K8S_DASH_HELM_CHART_VERSION"
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --version=$K8S_DASH_HELM_CHART_VERSION \
  --namespace kubernetes-dashboard \
  --values /opt/dash-values.yaml
