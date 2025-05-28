#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: apply-cert-manager-prereqs.sh
# Author: Dheny (@furiatona on GitHub)
# Description: Applies cert-manager ClusterIssuer and Certificate prerequisites
# -----------------------------------------------------------------------------

echo "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "Applying cert-manager prerequisites..."
kubectl apply -f infrastructure/cert-manager-prereqs.yaml

echo "Verifying ClusterIssuer and Certificate..."
kubectl get clusterissuer letsencrypt-prod -o wide
kubectl get certificate -n istio-system argocd-cert -o wide
kubectl get secret -n istio-system argocd-tls-secret -o wide

echo "Wait a few minutes for Let's Encrypt to issue the certificate."
echo "Check certificate status with: kubectl describe certificate -n istio-system argocd-cert"