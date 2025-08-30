# GitOps Tools Docker Image

[![Docker Build](https://img.shields.io/github/actions/workflow/status/ajaykumar4/gitops-tools/release.yaml?branch=main&style=for-the-badge)](https://github.com/ajaykumar4/gitops-tools/actions/workflows/release.yaml)
[![GitHub release](https://img.shields.io/github/v/release/ajaykumar4/gitops-tools?style=for-the-badge)](https://github.com/ajaykumar4/gitops-tools/)
[![Docker Pulls](https://img.shields.io/docker/pulls/ajaykumar4/gitops-tools.svg?style=for-the-badge)](https://hub.docker.com/r/ajaykumar4/gitops-tools)
[![GitHub License](https://img.shields.io/github/license/ajaykumar4/gitops-tools?style=for-the-badge)](./LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/ajaykumar4/gitops-tools?style=for-the-badge)](https://github.com/ajaykumar4/gitops-tools/stargazers)

---

## Table of Contents

- [About](#about)
- [Key Features](#key-features)
- [Included Tools](#included-tools)
- [Helm Plugins](#helm-plugins)
- [ArgoCD Integration](#argocd-integration)
- [Usage](#usage)
- [Contributing](#contributing)

---

## About

A curated, multi-platform Docker image containing a suite of essential tools for modern GitOps workflows. Built on Alpine Linux for a minimal footprint and supporting linux/amd64 and linux/arm64 architectures — ideal for CI/CD pipelines and local development (including Apple Silicon).

All tool versions are pinned and kept up-to-date automatically via Renovate Bot.

---

## Key Features

- **Multi-Platform Support:** Built for linux/amd64 and linux/arm64.  
- **Lightweight:** Based on the minimal alpine:3.22 image.  
- **Comprehensive Toolset:** Includes a wide range of popular and necessary tools for Kubernetes and Helm-based GitOps.  
- **Version Pinned:** All tool versions are explicitly pinned and managed.  
- **CI/CD Ready:** Perfect for use as a runner image in GitHub Actions, GitLab CI, CircleCI, and more.  
- **Pre-configured Helm:** Comes with popular Helm plugins like helm-secrets, helm-diff, and helm-git pre-installed.  

---

## Included Tools

This image packages the following command-line tools. All binaries are located in the `/gitops-tools` directory.

| Tool         | Version  | Description                                                     |
|--------------|----------|-----------------------------------------------------------------|
| age          | <!-- # renovate: datasource=github-releases depName=FiloSottile/age --> 1.2.1   | A simple, modern, and secure file encryption tool.              |
| argocd-vault-plugin | <!-- # renovate: datasource=github-releases depName=argoproj-labs/argocd-vault-plugin --> 1.18.1 | ArgoCD plugin to inject secrets from Vault, AWS, Bitwarden, etc., into manifests. |
| curl         | <!-- # renovate: datasource=github-releases depName=moparisthebest/static-curl --> 8.11.0  | A static build of the command-line tool for transferring data with URL syntax. |
| helmfile     | <!-- # renovate: datasource=github-releases depName=helmfile/helmfile --> 1.1.5   | A declarative spec for deploying Helm charts.                   |
| jq           | <!-- # renovate: datasource=github-releases depName=jqlang/jq --> 1.7.1   | A lightweight and flexible command-line JSON processor.         |
| kubectl      | <!-- # renovate: datasource=github-tags depName=kubernetes/kubectl --> 1.33.4  | The Kubernetes command-line tool.                               |
| kustomize    | <!-- # renovate: datasource=github-releases depName=kubernetes-sigs/kustomize --> 5.7.1   | Customization of Kubernetes YAML configurations.                |
| kustomize-sops (ksops) | <!-- # renovate: datasource=github-releases depName=viaduct-ai/kustomize-sops --> 4.3.3 | A kustomize plugin for decrypting SOPS-encrypted resources.   |
| sops         | <!-- # renovate: datasource=github-releases depName=getsops/sops --> 3.10.2  | A tool for managing secrets, which works with AWS KMS, GCP KMS, etc. |
| vals         | <!-- # renovate: datasource=github-releases depName=helmfile/vals --> 0.42.0  | A tool for fetching and templating values from various sources (Vault, SSM, etc.). |
| yq           | <!-- # renovate: datasource=github-releases depName=mikefarah/yq --> 4.47.1  | A command-line YAML, JSON, and XML processor.                   |

All binaries are installed in `/gitops-tools`.
---

## Helm Plugins

| Plugin      | Version  | Description                                                    |
|-------------|----------|----------------------------------------------------------------|
| helm-diff   | <!-- # renovate: datasource=github-releases depName=databus23/helm-diff --> 3.12.5  | A helm plugin for previewing helm upgrade as a diff.           |
| helm-git    | <!-- # renovate: datasource=github-releases depName=aslafy-z/helm-git --> 1.4.0   | A helm plugin for installing charts from Git repositories.     |
| helm-secrets| <!-- # renovate: datasource=github-releases depName=jkroepke/helm-secrets --> 4.6.7   | A helm plugin for managing secrets with sops or other secret backends. |

Helm is wrapped in a script that automatically uses `helm-secrets` for seamless decryption.

---

## ArgoCD Integration

To use these tools with ArgoCD, you can configure the `argocd-repo-server` to use this image as an `initContainer`. The `initContainer` will copy the tools to a shared `emptyDir` volume, making them available to the main repo-server container.

This allows ArgoCD to natively handle encrypted Helm charts and other GitOps functionalities provided by the tools.

### Configure ArgoCD ConfigMap:

First, update the `argocd-cm` ConfigMap to register the helm-secrets decryption schemes.

```
configs:
  cm:
    helm.valuesFileSchemes: >-
      secrets+gpg-import, secrets+gpg-import-kubernetes,
      secrets+age-import, secrets+age-import-kubernetes,
      secrets, secrets+literal,
      https
```

Configure `argocd-cm` ConfigMap to Register AVP-based CMP Plugins

```
configs:
  cmp:
    create: true
    plugins:
      avp-kustomize:
        allowConcurrency: true
        lockRepo: false
        init:
          command: [sh]
          args: [-c, 'echo "Initializing..."']
        discover:
          find:
            command:
              - find
              - "."
              - -name
              - kustomization.yaml
        generate:
          command:
            - sh
            - "-c"
            - "kustomize build --enable-alpha-plugins --enable-exec . | argocd-vault-plugin generate -"
```

### Create a Secret for Private Keys:

For age encrypted secrets, create a Kubernetes secret containing your private key. The SOPS_AGE_KEY_FILE environment variable points to this key inside the container.

```
# The secret name 'helm-secrets-private-keys' and the key 'key.txt' should match the values in the repoServer patch below.
kubectl create secret generic helm-secrets-private-keys --from-file=key.txt=/path/to/your/age-key.txt
```
### Patch the `argocd-repo-server` Deployment:

Apply the following patch to your argocd-repo-server deployment. This sets up the initContainer, volume mounts, and environment variables required for the tools to function correctly.

```
repoServer:
  initContainers:
    - name: gitops-tools
      image: ajaykumar4/gitops-tools:2025.8.0
      imagePullPolicy: Always
      command: [sh, -ec]
      args:
        - |
          mkdir -p /custom-tools/
          cp -rf /gitops-tools/* /custom-tools
          chmod +x /custom-tools/*
      volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
  env:
    - name: HELM_PLUGINS
      value: /custom-tools/helm-plugins/
    - name: HELM_SECRETS_CURL_PATH
      value: /custom-tools/curl
    - name: HELM_SECRETS_SOPS_PATH
      value: /custom-tools/sops
    - name: HELM_SECRETS_VALS_PATH
      value: /custom-tools/vals
    - name: HELM_SECRETS_KUBECTL_PATH
      value: /custom-tools/kubectl
    - name: HELM_SECRETS_BACKEND
      value: sops
    # https://github.com/jkroepke/helm-secrets/wiki/Security-in-shared-environments
    - name: HELM_SECRETS_VALUES_ALLOW_SYMLINKS
      value: "false"
    - name: HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH
      value: "true"
    - name: HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL
      value: "false"
    - name: HELM_SECRETS_WRAPPER_ENABLED
      value: "true"
    - name: HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR
      value: "true"
    - name: HELM_SECRETS_HELM_PATH
      value: /usr/local/bin/helm
    - name: SOPS_AGE_KEY_FILE # For age
      value: /helm-secrets-private-keys/key.txt
  volumes:
    - name: custom-tools
      emptyDir: {}
    - name: helm-secrets-private-keys
      secret:
        secretName: helm-secrets-private-keys
  volumeMounts:
    - mountPath: /custom-tools
      name: custom-tools
    - mountPath: /usr/local/sbin/helm
      subPath: helm
      name: custom-tools
    - mountPath: /usr/local/bin/kustomize
      name: custom-tools
      subPath: kustomize
    - mountPath: /usr/local/bin/ksops
      name: custom-tools
      subPath: ksops
    - mountPath: /helm-secrets-private-keys/
      name: helm-secrets-private-keys
  extraContainers:
    # argocd-vault-plugin with Kustomize
    - name: avp-kustomize
      command: [/var/run/argocd/argocd-cmp-server]
      image: quay.io/argoproj/argocd
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      env:
        - name: HELM_PLUGINS
          value: /custom-tools/helm-plugins/
        - name: HELM_SECRETS_CURL_PATH
          value: /custom-tools/curl
        - name: HELM_SECRETS_SOPS_PATH
          value: /custom-tools/sops
        - name: HELM_SECRETS_VALS_PATH
          value: /custom-tools/vals
        - name: HELM_SECRETS_KUBECTL_PATH
          value: /custom-tools/kubectl
        - name: HELM_SECRETS_BACKEND
          value: sops
        # https://github.com/jkroepke/helm-secrets/wiki/Security-in-shared-environments
        - name: HELM_SECRETS_VALUES_ALLOW_SYMLINKS
          value: "false"
        - name: HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH
          value: "true"
        - name: HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL
          value: "false"
        - name: HELM_SECRETS_WRAPPER_ENABLED
          value: "true"
        - name: HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR
          value: "true"
        - name: HELM_SECRETS_HELM_PATH
          value: /usr/local/bin/helm
        - name: SOPS_AGE_KEY_FILE # For age
          value: /helm-secrets-private-keys/key.txt
        - name: AVP_TYPE
          value: kubernetessecret
      volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /tmp
          name: tmp
        # Register plugins into sidecar
        - mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: avp-kustomize.yaml
          name: argocd-cmp-cm
        - mountPath: /usr/local/sbin/helm
          subPath: helm
          name: custom-tools
        - mountPath: /usr/local/bin/kustomize
          name: custom-tools
          subPath: kustomize
        - mountPath: /usr/local/bin/ksops
          name: custom-tools
          subPath: ksops
        - mountPath: /usr/local/bin/argocd-vault-plugin
          name: custom-tools
          subPath: argocd-vault-plugin
        - mountPath: /helm-secrets-private-keys/
          name: helm-secrets-private-keys
```

## Usage

### ArgoCD with Helm-Secrets

#### Argo Application
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudflare-dns
  namespace: argo-system
  annotations:
    argocd.argoproj.io/sync-wave: '0'
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: kubernetes
  sources:
    - repoURL: "https://github.com/ajaykumar4/home-lab.git"
      path: kubernetes/apps/network/cloudflare-dns
      targetRevision: main
      ref: repo
    - repoURL: https://kubernetes-sigs.github.io/external-dns
      chart: external-dns
      targetRevision: 1.17.0
      helm:
        releaseName: cloudflare-dns
        valueFiles:
          - $repo/kubernetes/apps/network/cloudflare-dns/values.sops.yaml
  destination:
    name: in-cluster
    namespace: network
  syncPolicy:
    automated:
      allowEmpty: true
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```
### ArgoCD with kustomize-sops (ksops)

#### secret.sops.yaml
```
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-dns-secret
stringData:
  api-token: sNdfyrfE-sdgdghfdghfgdjhfgzcvhnd
```

#### secret-generator.yaml
```
apiVersion: viaduct.ai/v1
kind: ksops
metadata:
  name: cloudflare-dns-secret-generator
  annotations:
    config.kubernetes.io/function: |
      exec:
        path: ksops
files:
  - ./secret.sops.yaml
```

#### kustomization.yaml
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
generators:
  - ./secret-generator.yaml
```

## Contributing

Contributions and suggestions are welcome! To update tool versions, submit a pull request or wait for Renovate Bot to open one automatically.