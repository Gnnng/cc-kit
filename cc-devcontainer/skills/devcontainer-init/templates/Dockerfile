FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y tmux jq && rm -rf /var/lib/apt/lists/*

USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash
USER root
