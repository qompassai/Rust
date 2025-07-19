#!/usr/bin/env bash
# /qompassai/rust/scripts/quickstart.sh
# Qompass AI Rust Quick Start
# Copyright (C) 2025 Qompass AI, All rights reserved
####################################################

set -euo pipefail
IFS=$'\n\t'
detect_os() {
  unameOut="$(uname -s)"
  case "${unameOut}" in
  Linux*) OS="linux" ;;
  Darwin*) OS="macos" ;;
  CYGWIN* | MINGW* | MSYS*) OS="windows" ;;
  *) OS="unknown" ;;
  esac
  echo "==> Detected OS: $OS"
}
install_rustup_if_missing() {
  if ! command -v rustup &>/dev/null; then
    echo "⚠ rustup not found. Installing rustup for $OS..."
    case "$OS" in
    linux | macos)
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      export PATH="$HOME/.cargo/bin:$PATH"
      ;;
    windows)
      echo "❌ Automated rustup install is not supported on Windows via this script."
      echo "➡ Please install manually from https://rustup.rs/"
      exit 1
      ;;
    *)
      echo "❌ Unknown OS. Cannot install rustup."
      exit 1
      ;;
    esac
  else
    echo "✅ rustup found"
  fi
}
declare -a toolchains=(
  stable-x86_64-unknown-linux-gnu
  nightly-x86_64-unknown-linux-gnu
)
declare -a components=(
  cargo
  clippy
  rustfmt
  rust-src
  rust-docs
  rustc
  rust-analyzer
  llvm-tools-preview
)
declare -a targets=(
  x86_64-unknown-linux-musl
  x86_64-unknown-linux-gnu
  aarch64-unknown-linux-gnu
  aarch64-apple-darwin
  wasm32-wasi
  riscv64gc-unknown-linux-gnu
  aarch64-unknown-linux-rocm
)
declare -a cargo_tools=(
  bacon
  bacon-ls
  bat
  cargo2nix
  crane
  cargo-zigbuild
  cross
  cargo-debugger
  cargo-lipo
  cargo-apk
  cargo-godot
  cargo-ndk
  maturin
  cargo-leptos
  cxxbridge-cmd
  flamegraph
  cargo-bloat
  cargo-udeps
  cargo-sweep
  nixpkgs-fmt
)

main() {
  echo "==> Setting up Rust toolchains..."
  setup_toolchains
  echo "==> Adding cross-compilation targets..."
  add_targets
  echo "==> Installing cargo tools..."
  install_cargo_tools
  echo "==> Configuring Nix integration..."
  setup_nix
  echo "✅ Rust cross-compilation environment setup complete!"
}
setup_toolchains() {
  for toolchain in "${toolchains[@]}"; do
    echo "▪ Installing $toolchain"
    rustup toolchain install "$toolchain"

    echo "  Adding components to $toolchain"
    for component in "${components[@]}"; do
      rustup component add "$component" --toolchain "$toolchain" || true
    done
  done
}
add_targets() {
  for toolchain in "${toolchains[@]}"; do
    echo "▪ Processing targets for $toolchain"
    for target in "${targets[@]}"; do
      rustup target add "$target" --toolchain "$toolchain" || true
    done
  done
}
install_cargo_tools() {
  for tool in "${cargo_tools[@]}"; do
    echo "▪ Installing $tool"
    cargo install "$tool" --locked --force || true
  done
  if ! command -v zig &>/dev/null; then
    cargo install zig --locked --force
  fi
}
EOF
main "$@"
