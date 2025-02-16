ARG BASE_IMAGE=docker.io/library/alpine:3.21@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c

FROM $BASE_IMAGE
  
LABEL org.opencontainers.image.source https://github.com/ajaykumar4/gitops-tools
  
ENV DEBIAN_FRONTEND=noninteractive
ARG TARGETPLATFORM
ARG BUILDPLATFORM
  
RUN echo "I am running on final $BUILDPLATFORM, building for $TARGETPLATFORM"
  
# binary versions
# renovate: datasource=github-releases depName=FiloSottile/age
ARG AGE_VERSION=v1.2.1
# renovate: datasource=github-releases depName=jqlang/jq
ARG JQ_VERSION=1.7.1
# renovate: datasource=github-releases depName=helm/helm
# ARG HELM_VERSION=v3.15.3
# renovate: datasource=github-releases depName=helmfile/helmfile
ARG HELMFILE_VERSION=0.171.0
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize extractVersion=kustomize/v
ARG KUSTOMIZE_VERSION=5.6.0
# renovate: datasource=github-releases depName=getsops/sops
ARG SOPS_VERSION=v3.9.4
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=v4.45.1
# renovate: datasource=github-releases depName=moparisthebest/static-curl
ARG CURL_VERSION=v8.11.0
# renovate: datasource=github-releases depName=kubernetes/kubectl
ARG KUBECTL_VERSION=v1.30.2
# renovate: datasource=github-releases depName=helmfile/vals
ARG VALS_VERSION=0.39.1
# renovate: datasource=github-releases depName=viaduct-ai/kustomize-sops
ARG KSOPS_VERSION=4.3.3
  
RUN mkdir -p /gitops-tools/helm-plugins

RUN \
    GO_ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/') && \
    wget -qO "/gitops-tools/sops"      "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${GO_ARCH}" && \
    wget -qO-                          "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-${GO_ARCH}.tar.gz" | tar zxv --strip-components=1 -C /gitops-tools age/age age/age-keygen && \
    wget -qO-                          "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${GO_ARCH}.tar.gz" | tar zxv -C /gitops-tools helmfile && \
    wget -qO "/gitops-tools/jq"        "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${GO_ARCH}" && \
    wget -qO "/gitops-tools/yq"        "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${GO_ARCH}" && \
    wget -qO "/gitops-tools/kubectl"   "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${GO_ARCH}/kubectl" && \
    wget -qO-                          "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${GO_ARCH}.tar.gz" | tar zxv -C /gitops-tools kustomize && \
    wget -qO-                          "https://github.com/helmfile/vals/releases/download/v${VALS_VERSION}/vals_${VALS_VERSION}_linux_${GO_ARCH}.tar.gz" | tar zxv -C /gitops-tools vals && \
    true

RUN \
    GO_ARCH=$(uname -m | sed -e 's/x86_64/amd64/') && \
    wget -qO "/gitops-tools/curl"      "https://github.com/moparisthebest/static-curl/releases/download/${CURL_VERSION}/curl-${GO_ARCH}" && \
    true

RUN \
    GO_ARCH=$(uname -m | sed -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/') && \
    wget -qO-                          "https://github.com/viaduct-ai/kustomize-sops/releases/download/v${KSOPS_VERSION}/ksops_${KSOPS_VERSION}_Linux_${GO_ARCH}.tar.gz" | tar zxv -C /gitops-tools ksops && \
    true

# plugin versions
# renovate: datasource=github-releases depName=databus23/helm-diff
ARG HELM_DIFF_VERSION=v3.10.0
# renovate: datasource=github-releases depName=aslafy-z/helm-git
ARG HELM_GIT_VERSION=v1.3.0
# renovate: datasource=github-releases depName=jkroepke/helm-secrets
ARG HELM_SECRETS_VERSION=v4.6.2

RUN \
    GO_ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/') && \
    wget -qO-                          "https://github.com/jkroepke/helm-secrets/releases/download/${HELM_SECRETS_VERSION}/helm-secrets.tar.gz" | tar -C /gitops-tools/helm-plugins -xzf- && \
    wget -qO-                          "https://github.com/databus23/helm-diff/releases/download/${HELM_DIFF_VERSION}/helm-diff-linux-${GO_ARCH}.tgz" | tar -C /gitops-tools/helm-plugins -xzf- && \
    wget -qO-                          "https://github.com/aslafy-z/helm-git/archive/refs/tags/${HELM_GIT_VERSION}.tar.gz" | tar -C /gitops-tools/helm-plugins -xzf- && \
    cp /gitops-tools/helm-plugins/helm-secrets/scripts/wrapper/helm.sh /gitops-tools/helm && \
    chmod +x /gitops-tools/* && \
    true

WORKDIR /gitops-tools