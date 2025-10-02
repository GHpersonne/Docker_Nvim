FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root

# Outils de base + dépendances utiles
# - build-essential, unzip : requis pour compiler des parsers Tree-sitter
# - ripgrep, fzf : utilitaires courants pour nvim
# - python3, nodejs/npm : souvent requis par plugins/LSP/formatters
# - libfuse2 : pour AppImage
RUN apt-get update && apt-get install -y \
    curl git ca-certificates ripgrep fzf \
    build-essential unzip python3 python3-pip \
    nodejs npm \
    libfuse2 \
  && rm -rf /var/lib/apt/lists/*

# Installer Neovim (AppImage dernière version stable)
RUN curl -L https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage -o /usr/local/bin/nvim.appimage \
 && chmod +x /usr/local/bin/nvim.appimage \
 && /usr/local/bin/nvim.appimage --appimage-extract \
 && mv squashfs-root /opt/nvim \
 && ln -s /opt/nvim/AppRun /usr/local/bin/nvim

# Cloner la config nvim cible (GHpersonne/nvim)
# On enlève le .git pour figer l'état dans l'image
RUN git clone --depth=1 https://github.com/GHpersonne/nvim.git /root/.config/nvim \
 && rm -rf /root/.config/nvim/.git

# Préinstallation headless:
# 1) Installer tous les plugins via Lazy.nvim
# 2) Installer/mettre à jour les parsers Tree-sitter demandés (TSUpdate Sync)
# 3) Installer les outils Mason (LSP, DAP, formatters) si la config les déclare
# Les commandes utilisent :silent et +qa pour terminer proprement en headless.
# NB: Certaines configs déclenchent Mason via Lazy, d'autres via ensure_installed;
#     on enchaîne plusieurs commandes pour couvrir ces cas.
RUN nvim --headless \
  "+Lazy! sync" \
  "+qa" || true

# Treesitter: compile/installe en build pour éviter la recompilation au premier run
RUN nvim --headless \
  "+lua vim.defer_fn(function() require('lazy').load() end, 0)" \
  "+TSUpdateSync" \
  "+qa" || true

# Mason: installation si déclaré (mason.nvim / mason-tool-installer / mason-lspconfig)
# On tente plusieurs entrées idiomatiques selon les configs LazyVim/Custom:
RUN nvim --headless \
  "+lua pcall(function() require('mason').setup() end)" \
  "+lua pcall(function() require('mason-registry').refresh() end)" \
  "+lua pcall(function() require('mason-tool-installer').run_on_start() end)" \
  "+lua pcall(function() require('mason-tool-installer').install() end)" \
  "+lua pcall(function() require('mason-lspconfig').setup({automatic_installation = true}) end)" \
  "+LspInstall" \
  "+qa" || true

# Option: relancer Lazy pour finaliser post-install (si hooks post-update)
RUN nvim --headless "+Lazy! sync" "+qa" || true

SHELL ["/bin/bash", "-lc"]
CMD ["nvim"]

