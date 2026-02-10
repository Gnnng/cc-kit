FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y tmux jq && rm -rf /var/lib/apt/lists/*

COPY tmux.conf /home/vscode/.tmux.conf
