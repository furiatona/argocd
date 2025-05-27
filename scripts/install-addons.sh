#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: install-addons.sh
# Author: Dheny (@furiatona on GitHub)
# Description: Enables necessary MicroK8s addons for ArgoCD with Istio and cert-manager
# -----------------------------------------------------------------------------

echo "Enabling MicroK8s addons..."
microk8s enable helm3
microk8s enable dns
microk8s enable cert-manager
microk8s enable istio
microk8s enable metallb:104.168.87.74-104.168.87.74 # Replace with your actual MetalLB IP range

echo "Firewall configuration for MetalLB..."
ufw allow 443/tcp
ufw allow 80/tcp

echo "Verifying addon status..."
microk8s status

echo "Addons enabled. Ensure cert-manager, metallb istio pods are running before proceeding."
echo "Check with: microk8s kubectl get pods -n cert-manager"
echo "Check with: microk8s kubectl get pods -n istio-system"
echo "Check with: microk8s kubectl get svc -n istio-system istio-ingressgateway"