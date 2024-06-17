# https://github.com/argoproj/argo-cd/blob/master/Dockerfile
#
# docker build --pull -t foobar .
# docker run --rm -ti             --entrypoint bash foobar
# docker run --rm -ti --user root --entrypoint bash foobar

ARG BASE_IMAGE=docker.io/library/alpine:latest

FROM $BASE_IMAGE
FROM viaductoss/ksops:v4.3.1 AS ksops

LABEL org.opencontainers.image.source https://github.com/ajaykumar4/argocd-plugins

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "I am running on final $BUILDPLATFORM, building for $TARGETPLATFORM"

# aws
# https://www.educative.io/collection/page/6630002/6521965765984256/6553354502668288
#
#ARG INSTALL_AWS_TOOLS
#RUN apt-get update && apt-get install --no-install-recommends -y \
#    awscli \
#    && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# az cli
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
#
#ARG INSTALL_AZURE_TOOLS
#RUN apt-get update && apt-get install --no-install-recommends -y \
#    ca-certificates curl apt-transport-https lsb-release gnupg \
#    && \
#    mkdir -p /etc/apt/keyrings && \
#    curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null && \
#    chmod go+r /etc/apt/keyrings/microsoft.gpg && \
#    AZ_REPO=$(lsb_release -cs) && \
#    echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list && \
#    apt-get update && apt-get install --no-install-recommends -y \
#    azure-cli && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# gcloud cli
# https://cloud.google.com/sdk/docs/install#deb
#
#ARG INSTALL_GCLOUD_TOOLS
#RUN apt-get update && apt-get install --no-install-recommends -y \
#    apt-transport-https ca-certificates gnupg \
#    && \
#    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
#    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
#    apt-get update && apt-get install --no-install-recommends -y \
#    google-cloud-cli && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# binary versions
# renovate: datasource=github-tags depName=FiloSottile/age
ARG AGE_VERSION=v1.1.1
# renovate: datasource=github-tags depName=jqlang/jq
ARG JQ_VERSION=1.7.1
ARG HELM2_VERSION=v2.17.0
# renovate: datasource=github-tags depName=helm/helm
ARG HELM3_VERSION=v3.15.2
# renovate: datasource=github-tags depName=helmfile/helmfile
ARG HELMFILE_VERSION=0.165.0
# renovate: datasource=github-tags depName=kubernetes-sigs/kustomize extractVersion=kustomize/v
ARG KUSTOMIZE_VERSION=5.4.2
# renovate: datasource=github-tags depName=mozilla/sops
ARG SOPS_VERSION=v3.8.1
# renovate: datasource=github-tags depName=mikefarah/yq
ARG YQ_VERSION=v4.44.1
# renovate: datasource=github-tags depName=helmfile/vals
ARG VALS_VERSION=0.37.2

# relevant for kubectl if installed
# renovate: datasource=github-tags depName=bitnami-labs/sealed-secrets
ARG KUBESEAL_VERSION=0.26.3
# renovate: datasource=github-tags depName=kubernetes/kubectl
ARG KUBECTL_VERSION=v1.30.2
# renovate: datasource=github-tags depName=kubernetes-sigs/krew
ARG KREW_VERSION=v0.4.4

RUN \
    GO_ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/') && \
    mkdir -p /custom-tools && \
    wget -qO-                          "https://get.helm.sh/helm-${HELM2_VERSION}-linux-${GO_ARCH}.tar.gz" | tar zxv --strip-components=1 -C /tmp linux-${GO_ARCH}/helm && mv /tmp/helm /custom-tools/helm-v2 && \
    wget -qO-                          "https://get.helm.sh/helm-${HELM3_VERSION}-linux-${GO_ARCH}.tar.gz" | tar zxv --strip-components=1 -C /tmp linux-${GO_ARCH}/helm && mv /tmp/helm /custom-tools/helm-v3 && \
    wget -qO "/custom-tools/sops"     "https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${GO_ARCH}" && \
    wget -qO-                          "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-${GO_ARCH}.tar.gz" | tar zxv --strip-components=1 -C /custom-tools age/age age/age-keygen && \
    wget -qO-                          "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${GO_ARCH}.tar.gz" | tar zxv -C /custom-tools helmfile && \
    wget -qO-                          "https://github.com/helmfile/vals/releases/download/v${VALS_VERSION}/vals_${VALS_VERSION}_linux_${GO_ARCH}.tar.gz" | tar zxv -C /custom-tools vals && \
    wget -qO "/custom-tools/yq"       "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${GO_ARCH}" && \
    wget -qO "/custom-tools/jq"       "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${GO_ARCH}" && \
    wget -qO "/custom-tools/kubectl"  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${GO_ARCH}/kubectl" && \
    wget -qO-                          "https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_${GO_ARCH}.tar.gz" | tar zxv -C /tmp ./krew-linux_${GO_ARCH} && mv /tmp/krew-linux_${GO_ARCH} /custom-tools/kubectl-krew && \
    wget -qO-                          "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-${GO_ARCH}.tar.gz" | tar zxv -C /custom-tools kubeseal && \
    wget -qO-                          "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${GO_ARCH}.tar.gz" | tar zxv -C /custom-tools kustomize && \
    true

COPY src/*.sh /custom-tools/
COPY --from=ksops ksops /custom-tools/ksops

RUN \
    ln -sf /custom-tools/helm-v3 /custom-tools/helm && \
    chown root:root /custom-tools/* && chmod 755 /custom-tools/*

WORKDIR /custom-tools/cmp-server/config/
COPY plugin.yaml ./
WORKDIR /custom-tools

# repo-server containers use /helm-working-dir (empty dir volume helm-working-dir)
#
# HELM_CACHE_HOME=/helm-working-dir
# HELM_CONFIG_HOME=/helm-working-dir
# HELM_DATA_HOME=/helm-working-dir
#
ENV HELM_CACHE_HOME=/custom-tools/helm/cache
#ENV HELM_CONFIG_HOME=/custom-tools/helm/config
ENV HELM_DATA_HOME=/custom-tools/helm/data
ENV KREW_ROOT=/custom-tools/krew
ENV PATH="/custom-tools:${KREW_ROOT}/bin:$PATH"

# plugin versions
 # renovate: datasource=github-tags depName=databus23/helm-diff
ARG HELM_DIFF_VERSION=v3.9.7
# renovate: datasource=github-tags depName=aslafy-z/helm-git
ARG HELM_GIT_VERSION=v0.16.0
# renovate: datasource=github-tags depName=jkroepke/helm-secrets
ARG HELM_SECRETS_VERSION=v4.6.0

RUN \
  helm-v3 plugin install https://github.com/databus23/helm-diff   --version ${HELM_DIFF_VERSION} && \
  helm-v3 plugin install https://github.com/aslafy-z/helm-git     --version ${HELM_GIT_VERSION} && \
  helm-v3 plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION} && \
  kubectl krew update && \
  mkdir -p ${KREW_ROOT}/bin && \
  true

# array is exec form, string is shell form
# this binary in injected via a shared folder with the repo server
#ENTRYPOINT [/var/run/argocd/argocd-cmp-server]
