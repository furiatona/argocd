#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: apply-istio-resources.sh
# Author: Dheny (@furiatona on GitHub)
# Description: Applies Istio Gateway and VirtualService for ArgoCD
# -----------------------------------------------------------------------------

echo "Applying Istio Gateway and VirtualService..."
kubectl apply -f templates/istio-resources.yaml

echo "Verifying Istio resources..."
kubectl get gateway -n argocd
kubectl get virtualservice -n argocd

echo "Ensure Istio ingress gateway is running..."
kubectl get pods -n istio-system

echo "ArgoCD should be accessible at https://cd.apps.aryaduta.co.id"
echo "If not accessible, verify DNS settings in Cloudflare and port 80/443 accessibility."