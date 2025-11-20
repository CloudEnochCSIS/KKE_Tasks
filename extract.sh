#!/bin/bash
set -e

BACKUP_DIR="k8s-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

echo "=== Extracting Kubernetes Configuration ==="

# Export namespaces list
kubectl get ns -o json > $BACKUP_DIR/namespaces.json

# Key namespaces to backup
NAMESPACES="argocd cert-manager default external-secrets haproxy-controller jenkins keda kube-node-lease kube-public kube-system metallb-system monitoring registry tractusx-edc vault"

for ns in $NAMESPACES; do
    echo "Backing up namespace: $ns"
    mkdir -p $BACKUP_DIR/$ns
    
    # Get all resources
    kubectl get all,cm,secret,ing,pvc,sa,role,rolebinding,networkpolicy -n $ns -o yaml > $BACKUP_DIR/$ns/all-resources.yaml 2>/dev/null || true
    
    # Get individual resource types for easier management
    kubectl get deployments -n $ns -o yaml > $BACKUP_DIR/$ns/deployments.yaml 2>/dev/null || true
    kubectl get services -n $ns -o yaml > $BACKUP_DIR/$ns/services.yaml 2>/dev/null || true
    kubectl get configmaps -n $ns -o yaml > $BACKUP_DIR/$ns/configmaps.yaml 2>/dev/null || true
    kubectl get ingress -n $ns -o yaml > $BACKUP_DIR/$ns/ingress.yaml 2>/dev/null || true
done

# Cluster-wide resources
echo "Backing up cluster-wide resources..."
kubectl get pv -o yaml > $BACKUP_DIR/persistent-volumes.yaml
kubectl get storageclass -o yaml > $BACKUP_DIR/storageclasses.yaml
kubectl get clusterrole -o yaml > $BACKUP_DIR/clusterroles.yaml
kubectl get clusterrolebinding -o yaml > $BACKUP_DIR/clusterrolebindings.yaml
kubectl get crd -o yaml > $BACKUP_DIR/crds.yaml

# Kubeadm config
kubectl -n kube-system get cm kubeadm-config -o yaml > $BACKUP_DIR/kubeadm-config.yaml

# Calico config
kubectl get ippool -o yaml > $BACKUP_DIR/calico-ippool.yaml 2>/dev/null || true

echo "=== Extracting Helm Releases ==="
mkdir -p $BACKUP_DIR/helm

helm list -A -o yaml > $BACKUP_DIR/helm/all-releases.yaml

# Extract values for each release
helm list -A --short | while read release; do
    ns=$(helm list -A | grep "^$release" | awk '{print $2}')
    if [ ! -z "$ns" ]; then
        echo "Extracting Helm release: $release (namespace: $ns)"
        helm get values $release -n $ns > $BACKUP_DIR/helm/values-$release.yaml
        helm get manifest $release -n $ns > $BACKUP_DIR/helm/manifest-$release.yaml
    fi
done

# Document current state
kubectl get nodes -o wide > $BACKUP_DIR/nodes-info.txt
kubectl version > $BACKUP_DIR/version-info.txt
kubectl cluster-info dump > $BACKUP_DIR/cluster-info.txt

echo "=== Backup complete in $BACKUP_DIR ==="
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
echo "Compressed backup: $BACKUP_DIR.tar.gz"