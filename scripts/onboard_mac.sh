#!/bin/zsh

set -euo pipefail

press_any_key_to_continue() {
    # -n 1   - read a single character
    # -t 600 - timeout after 600 secs (10 min)
    # -r     - disable backslash escapes. allows user to press backslash to continue
    # -s     - don't echo input to screen
    # -p $'' - prompt the user. the dollar sign in front of the quotes let's us include a newline at the end
    read -n 1 -t 600 -r -s -p $'\nPress any key to continue\n\n'
}

if [[ $(uname) != "Darwin" ]]; then
    echo 'Sorry. This onboarding script only works on macOS.'
    exit 1
fi

# if ~/.cargo/bin isn't in the $PATH. That's where Rust binaries get installed
# when you run `cargo install`.
if [[ $PATH != *"/.cargo/bin:"* ]]; then
    # shellcheck disable=SC2016
    echo 'Please add ~/.cargo/bin to your $PATH and rerun the script.' # use a single-quoted string on purpose to avoid expanding $PATH
    exit 1
fi

# SSH KEYS
# if the user doesn't have an ed25519 SSH key
if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
    echo 'No ed25519 SSH key found. We will create this key and add it to the'
    echo 'macOS keychain so you can ssh into VMs.'
    echo 'Generating ed25519 key...'
    ssh-keygen -t ed25519
    ssh-add -K ~/.ssh/id_ed25519 # add the new key to the macOS keychain
    echo ''
    echo 'An ed25519 SSH key has been generated and added to the macOS keychain.'
    echo 'Please add these lines to your ~/.ssh/config file and rerun this script.'
    echo ''
    echo 'Host *'
    echo '    AddKeysToAgent yes'
    echo '    UseKeychain yes'
    echo '    IdentityFile ~/.ssh/id_ed25519'
    echo ''
    exit 1
fi

# BREW
# if brew is not installed
if [[ ! -x "$(command -v brew)" ]]; then
    echo 'Installing brew...'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

echo 'Installing brew packages...'
brew update
brew bundle --file ../Brewfile

# GCLOUD
echo ''
echo 'Connecting the gcloud utility to your GCP account...'
echo 'You will be prompted to log in to your StudyBeast Google account (e.g. ryan@studybeast.com)'
vared -p 'Do you have a StudyBeast Google account? [Y/n]: ' -c HAS_GOOGLE_ACCOUNT

if [[ $HAS_GOOGLE_ACCOUNT =~ ^[Nn] ]]; then
    echo 'Please ask an admin to create an account for you in the StudyBeast organization.'
    echo 'Then rerun this script.'
    exit 1
fi

gcloud auth login
gcloud compute os-login ssh-keys add --key-file ~/.ssh/id_ed25519.pub --ttl 365d

# This is a bug in terraform-provider-google. Terraform can't enable the
# Cloud Resources Manager API because the google_project_service resource
# depends on it. See this issue for details:
#   https://github.com/terraform-providers/terraform-provider-google/issues/6101
gcloud services enable cloudresourcemanager.googleapis.com

# RUST
rustup target add x86_64-unknown-linux-musl
cargo install cargo-audit cargo-make cargo-tomlfmt cargo-tree

# WRAPPING UP
echo ''
echo 'System configuration complete. You will now be redirected to docker.com'
echo 'so you can download and install Docker Desktop.'

press_any_key_to_continue

open 'https://www.docker.com/products/docker-desktop'
