FROM flant/shell-operator:latest

ADD hooks /hooks

ENV KUBECTL_VER=1.18.0

RUN apk --no-cache add \
    bind-tools \
    curl \
    aws-cli \
    # Remove kubectl binary from flant container image since it ships the x86, arm version is needed
    && rm -rf /bin/kubectl \
    && wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VER}/bin/linux/arm64/kubectl \
    && chmod +x kubectl \
    && mv kubectl  /bin/ \
    && chmod +x /hooks/svc-watcher.sh   