#!/usr/bin/env bash
# Install the local speech tools used by i3 Toolkit → Capture → 4/5.
# Run on the Ubuntu desktop that runs this i3 configuration.
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    echo 'This installer supports Ubuntu/Debian. Install espeak-ng, build whisper.cpp, and download its multilingual base model on other distributions.' >&2
    exit 1
fi

source_dir="$HOME/.local/src/whisper.cpp"
model_dir="$HOME/.local/share/whisper.cpp/models"
model_file="$model_dir/ggml-base.bin"
bin_dir="$HOME/.local/bin"

sudo apt-get update
sudo apt-get install -y espeak-ng espeak-ng-espeak git cmake build-essential ffmpeg pulseaudio-utils xclip

mkdir -p -- "$(dirname -- "$source_dir")" "$model_dir" "$bin_dir"
if [[ ! -d $source_dir/.git ]]; then
    if [[ -e $source_dir ]]; then
        echo "Cannot clone whisper.cpp: $source_dir already exists and is not a Git checkout." >&2
        exit 1
    fi
    git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git "$source_dir"
fi

cmake -S "$source_dir" -B "$source_dir/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$source_dir/build" --config Release --parallel 4

if [[ ! -s $model_file ]]; then
    (cd "$source_dir" && sh ./models/download-ggml-model.sh base "$model_dir")
fi

binary="$source_dir/build/bin/whisper-cli"
[[ -x $binary && -s $model_file ]] || {
    echo 'whisper-cli or its multilingual base model is missing after installation.' >&2
    exit 1
}

link="$bin_dir/whisper-cli"
if [[ -L $link || ! -e $link ]]; then
    ln -sfn -- "$binary" "$link"
elif [[ $(readlink -f -- "$link") != $(readlink -f -- "$binary") ]]; then
    echo "Leaving the existing $link unchanged; it is not a symlink." >&2
fi

espeak-ng --version
espeak --version
"$binary" --help >/dev/null 2>&1 || true
printf 'Ready: %s\nModel: %s\n' "$binary" "$model_file"
printf 'Capture keys: Ctrl+Alt+T, C, 4 (read screenshot) or 5 (dictate).\n'
