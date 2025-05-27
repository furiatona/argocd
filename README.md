# ArgoCD + Istio Deployment with GitHub Actions
A ready-to-use GitOps setup to deploy ArgoCD and expose it via Istio Gateway and VirtualService using GitHub Actions and Helm.

## Deployment Steps

### 1. Prepare the Environment

- Ensure MicroK8s is installed and running:
    ```sh
    sudo microk8s status
    ```
- Configure Cloudflare DNS to point `cd.apps.example.com` to your cluster’s public IP.

### 2. Run setup scripts (in order) if running locally

```sh
./scripts/install-addons.sh # Run this on the MicroK8s server
# Run locally if your kubeconfig is already set up
./scripts/apply-cert-manager-prereqs.sh
./scripts/install-argocd.sh
./scripts/apply-istio-resources.sh
```

### 3. Access ArgoCD

- Open [https://cd.apps.example.com](https://cd.apps.example.com)
- Login with username: `admin`
- Retrieve the password:
    ```sh
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
    ```

## Notes

- **Security:**  
  After changing the ArgoCD admin password, delete the `argocd-initial-admin-secret` for security:
    ```sh
    kubectl delete secret -n argocd argocd-initial-admin-secret
    ```

---

**License:** MIT  
**Author:** [furiatona](https://github.com/furiatona)