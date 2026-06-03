# Use a stable Ubuntu base for the secure Codex devcontainer profile.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
ARG TARGETARCH
# renovate: datasource=npm packageName=@openai/codex versioning=npm
ARG CODEX_CLI_VERSION=0.134.0
# renovate: datasource=github-releases packageName=terraform-linters/tflint versioning=semver
ARG TFLINT_VERSION=v0.62.1
ARG SSM_PLUGIN_VERSION=1.2.650.0
ARG HASHICORP_APT_FINGERPRINT=798AEC654E5C15428C8E42EEAA16FCBCA621E701
ARG SSM_PLUGIN_SHA256_AMD64=16b3aac73cfbc134bc008b5388fb3f9f7f45c8e9af4f9eeb6585a611f75a3dd6
ARG SSM_PLUGIN_SHA256_ARM64=f94ee476ac327f573ccbb123e10be6e04e669aad0ad0f5c7699e4aefbfa01e0c

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install repository bootstrap dependencies first so later fetches fail loudly.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install HashiCorp GPG key and repository.
RUN set -eux; \
    tmp_dir="$(mktemp -d)"; \
    mkdir -p "${tmp_dir}/gnupg"; \
    chmod 700 "${tmp_dir}/gnupg"; \
    curl -fsSL https://apt.releases.hashicorp.com/gpg -o "${tmp_dir}/hashicorp.gpg"; \
    actual_fingerprint="$(GNUPGHOME="${tmp_dir}/gnupg" gpg --show-keys --with-colons "${tmp_dir}/hashicorp.gpg" \
      | awk -F: '$1 == "fpr" { print $10; exit }')"; \
    expected_fingerprint="$(printf '%s' "${HASHICORP_APT_FINGERPRINT}" | tr -d '[:space:]')"; \
    test "${actual_fingerprint}" = "${expected_fingerprint}"; \
    gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg "${tmp_dir}/hashicorp.gpg"; \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/hashicorp.list; \
    rm -rf "${tmp_dir}"

# Install Terraform and runtime dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
    bubblewrap \
    direnv \
    dnsutils \
    git \
    iproute2 \
    ipset \
    iptables \
    jq \
    nodejs \
    npm \
    openssh-client \
    ripgrep \
    terraform \
    && rm -rf /var/lib/apt/lists/*

# Allow Codex to use its Linux sandbox inside the devcontainer.
RUN chmod u+s /usr/bin/bwrap

# Install Codex CLI. Auth and session state live in the mounted ~/.codex volume.
RUN npm install -g "@openai/codex@${CODEX_CLI_VERSION}" \
    && npm cache clean --force

# Set up direnv hook for bash (default shell inside container)
RUN echo 'eval "$(direnv hook bash)"' >> /etc/bash.bashrc

# Install root-owned Codex startup helpers so postStartCommand does not execute
# workspace-writable scripts with elevated privileges.
COPY ensure-codex-sandbox-mode.sh ensure-codex-agents-md.sh ensure-shell-history.sh install-git-guardrails.sh init-codex-firewall.sh codex-allowed-domains.txt codex-global-agents.md /usr/local/share/codex-devcontainer/
RUN chown -R root:root /usr/local/share/codex-devcontainer \
    && chmod 755 /usr/local/share/codex-devcontainer/*.sh \
    && chmod 644 /usr/local/share/codex-devcontainer/codex-allowed-domains.txt /usr/local/share/codex-devcontainer/codex-global-agents.md

# Prepare user-owned config targets for mounted SSH config, direnv config, Codex state,
# shell history, and workspace.
RUN mkdir -p /home/vscode/.ssh /home/vscode/.config/direnv /home/vscode/.codex /home/vscode/.shell-history /workspace \
    && chown -R vscode:vscode /home/vscode/.ssh /home/vscode/.config /home/vscode/.codex /home/vscode/.shell-history /workspace \
    && chmod 700 /home/vscode/.ssh /home/vscode/.codex /home/vscode/.shell-history \
    && chmod 755 /home/vscode/.config /home/vscode/.config/direnv

# Install Terraform linting tools.
RUN set -eux; \
    build_arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "${build_arch}" in \
      amd64) tflint_arch="amd64" ;; \
      arm64) tflint_arch="arm64" ;; \
      *) echo "Unsupported architecture: ${build_arch}" >&2; exit 1 ;; \
    esac; \
    tmp_dir="$(mktemp -d)"; \
    tflint_zip="tflint_linux_${tflint_arch}.zip"; \
    tflint_base_url="https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}"; \
    curl -fsSL "${tflint_base_url}/${tflint_zip}" -o "${tmp_dir}/${tflint_zip}"; \
    curl -fsSL "${tflint_base_url}/checksums.txt" -o "${tmp_dir}/checksums.txt"; \
    (cd "${tmp_dir}" && grep " ${tflint_zip}$" checksums.txt | sha256sum -c -); \
    unzip -q "${tmp_dir}/${tflint_zip}" -d /usr/local/bin; \
    chmod +x /usr/local/bin/tflint; \
    tflint --version; \
    rm -rf "${tmp_dir}"

# Install AWS SSM Session Manager Plugin.
RUN build_arch="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "${build_arch}" in \
        amd64) ssm_arch="64bit"; ssm_sha256="${SSM_PLUGIN_SHA256_AMD64}" ;; \
        arm64) ssm_arch="arm64"; ssm_sha256="${SSM_PLUGIN_SHA256_ARM64}" ;; \
        *) echo "Unsupported architecture: ${build_arch}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/${SSM_PLUGIN_VERSION}/ubuntu_${ssm_arch}/session-manager-plugin.deb" -o session-manager-plugin.deb \
    && printf '%s  session-manager-plugin.deb\n' "${ssm_sha256}" | sha256sum -c - \
    && dpkg -i session-manager-plugin.deb \
    && session-manager-plugin --version \
    && rm -f session-manager-plugin.deb

# Switch to the vscode user
USER vscode
