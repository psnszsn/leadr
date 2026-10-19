#!/usr/bin/env bash
# Run from the repository root: nix develop -c bash scripts/generate-bindings.sh
# Generates bindings for the library versions pinned by flake.lock.
set -euo pipefail

upstream=https://github.com/ianprime0509/zig-gobject.git
revision=93afca136b82d4e8d2476298529fc6f6be4bcc07
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT

git init -q "$work_dir/upstream"
git -C "$work_dir/upstream" fetch --depth 1 "$upstream" "$revision"
git -C "$work_dir/upstream" checkout -q --detach FETCH_HEAD

gir_args=()
IFS=: read -ra data_dirs <<< "${XDG_DATA_DIRS:?Run inside nix develop}"
for dir in "${data_dirs[@]}"; do
    if [[ -d "$dir/gir-1.0" ]]; then
        gir_args+=("-Dgir-files-path=$dir/gir-1.0")
    fi
done
if (( ${#gir_args[@]} == 0 )); then
    echo "No GObject introspection files found; run inside nix develop." >&2
    exit 1
fi

cd "$work_dir/upstream"
zig build codegen -Dmodules=Adw-1 -Dmodules=Gtk4LayerShell-1.0 \
    -Dmodules=GstApp-1.0 "${gir_args[@]}"
cp -R zig-out/bindings/. "$repo_root/bindings/"
