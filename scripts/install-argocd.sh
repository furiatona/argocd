#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: install-argocd.sh
# Author: Dheny (@furiatona on GitHub)
# Description: Installs ArgoCD using Helm 3 with TLS configuration
# -----------------------------------------------------------------------------

echo "Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "Installing ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --values infrastructure/argocd-values.yaml \
  --version 7.6.7 \
  --create-namespace

echo "Verifying ArgoCD installation..."
kubectl get pods -n argocd
kubectl get svc -n argocd

echo "Retrieve the admin password with:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "Login to ArgoCD UI at https://cd.apps.aryaduta.co.id with username: admin"