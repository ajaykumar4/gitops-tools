ARG BASE_IMAGE=docker.io/library/alpine:3.20@sha256:b89d9c93e9ed3597455c90a0b88a8bbb5cb7188438f70953fede212a0c4394e0

FROM $BASE_IMAGE
  
LABEL org.opencontainers.image.source https://github.com/ajaykumar4/home-lab-argocd
  
ENV DEBIAN_FRONTEND=noninteractive
ARG TARGETPLATFORM
ARG BUILDPLATFORM
  
RUN echo "I am running on final $BUILDPLATFORM, building for $TARGETPLATFORM"
  
# binary versions
# renovate: datasource=github-tags depName=FiloSottile/age
ARG AGE_VERSION=v1.2.0
# renovate: datasource=github-tags depName=jqlang/jq
ARG JQ_VERSION=1.7.1
# renovate: datasource=github-tags depName=helm/helm
# ARG HELM_VERSION=v3.15.3
# renovate: datasource=github-tags depName=helmfile/helmfile
ARG HELMFILE_VERSION=0.166.0
# renovate: datasource=github-tags depName=kubernetes-sigs/kustomize extractVersion=kustomize/v
ARG KUSTOMIZE_VERSION=5.5.0
# renovate: datasource=github-tags depName=getsops/sops
ARG SOPS_VERSION=v3.9.0
# renovate: datasource=github-tags depName=mikefarah/yq
ARG YQ_VERSION=v4.44.2
# renovate: datasource=github-tags depName=moparisthebest/static-curl
ARG CURL_VERSION=v8.7.1
# renovate: datasource=github-tags depName=kubernetes/kubectl
ARG KUBECTL_VERSION=v1.30.2
# renovate: datasource=github-tags depName=helmfile/vals
ARG VALS_VERSION=0.37.3
# renovate: datasource=github-tags depName=viaduct-ai/kustomize-sops
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
# renovate: datasource=github-tags depName=databus23/helm-diff
ARG HELM_DIFF_VERSION=v3.9.9
# renovate: datasource=github-tags depName=aslafy-z/helm-git
ARG HELM_GIT_VERSION=v1.3.0
# renovate: datasource=github-tags depName=jkroepke/helm-secrets
ARG HELM_SECRETS_VERSION=v4.6.0

RUN \
    GO_ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/') && \
    wget -qO-                          "https://github.com/jkroepke/helm-secrets/releases/download/${HELM_SECRETS_VERSION}/helm-secrets.tar.gz" | tar -C /gitops-tools/helm-plugins -xzf- && \
    wget -qO-                          "https://github.com/databus23/helm-diff/releases/download/${HELM_DIFF_VERSION}/helm-diff-linux-${GO_ARCH}.tgz" | tar -C /gitops-tools/helm-plugins -xzf- && \
    wget -qO-                          "https://github.com/aslafy-z/helm-git/archive/refs/tags/${HELM_GIT_VERSION}.tar.gz" | tar -C /gitops-tools/helm-plugins -xzf- && \
    cp /gitops-tools/helm-plugins/helm-secrets/scripts/wrapper/helm.sh /gitops-tools/helm && \
    chmod +x /gitops-tools/* && \
    true

WORKDIR /gitops-tools