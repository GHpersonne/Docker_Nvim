FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root

# Outils de base + dépendances utiles
RUN apt-get update && apt-get install -y \
    curl git ca-certificates ripgrep fzf \
    build-essential unzip python3 python3-pip \
    nodejs npm \
    libfuse2 \
  && rm -rf /var/lib/apt/lists/*

# Installer Neovim (AppImage dernière version stable)
# Alternative: remplacer "stable" par un tag précis ou "nightly"
RUN curl -L https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage -o /usr/local/bin/nvim.appimage \
 && chmod +x /usr/local/bin/nvim.appimage \
 && /usr/local/bin/nvim.appimage --appimage-extract \
 && mv squashfs-root /opt/nvim \
 && ln -s /opt/nvim/AppRun /usr/local/bin/nvim

# Installer LazyVim starter
RUN git clone https://github.com/LazyVim/starter /root/.config/nvim \
 && rm -rf /root/.config/nvim/.git

# Pré-chauffer l’installation des plugins (optionnel)
RUN nvim --headless "+Lazy! sync" +qa || true

SHELL ["/bin/bash", "-lc"]
CMD ["nvim"]
