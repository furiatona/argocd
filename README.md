# ArgoCD + Istio Deployment with GitHub Actions
A ready-to-use GitOps setup to deploy ArgoCD and expose it via Istio Gateway and VirtualService using GitHub Actions and Helm.

## Deployment Steps

### 1. Prepare the Environment

- Copy example env
    ```sh
    cp env.sample .env
    ```
- Configure Cloudflare DNS to point `cd.apps.example.com` to your cluster’s public IP or Load Balancer.

### 2. Run setup scripts if running locally

```sh
./scripts/xborgctl --local
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