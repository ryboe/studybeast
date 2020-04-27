#!/usr/bin/env zsh
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
if [[ $PATH != *".cargo/bin:"* ]]; then
    # shellcheck disable=SC2016
    echo 'Please add ~/.cargo/bin to your $PATH and rerun the script.' # use a single-quoted string on purpose to avoid expanding $PATH
    exit 1
fi

if [[ -z "$GCP_PROJECT_ID" ]]; then
    echo '$GCP_PROJECT_ID is not set.'
    echo 'Please ask an admin to create a GCP user account and a dev project for you in the StudyBeast organization.'
    echo 'Set $GCP_PROJECT_ID in your shell config to something like this'
    echo ''
    echo '  export GCP_PROJECT_ID="studybeast-dev-ryan-boehning"'
    echo ''
    echo 'Our deployment scripts need this env var to know where to deploy your personal development cluster.'
    echo 'This cluster is your own StudyBeast sandbox, for developing and testing your branches.'
    echo ''
    echo 'When the env var is set, please rerun this script.'
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

    echo 'Please add these lines to your ~/.ssh/config file and rerun this script'
    echo ''
    echo 'Host *'
    echo '    AddKeysToAgent yes'
    echo '    ControlMaster auto'
    echo '    ControlPath ~/.ssh/sockets/%r@%h:%p'
    echo '    ControlPersist 600'
    echo '    IdentityFile ~/.ssh/id_ed25519'
    echo '    UseKeychain yes'
    echo ''
    exit 1
fi

# BREW
# if brew is not installed
if [[ ! -x "$(command -v brew)" ]]; then
    echo 'Installing brew...'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

echo ''
echo 'Installing brew packages...'
SCRIPT_PATH=$0:A
brew bundle --no-lock --file $SCRIPT_PATH/../Brewfile

# GCLOUD
echo ''
echo 'Connecting the gcloud utility to your GCP account...'

gcloud init
gcloud compute os-login ssh-keys add --key-file ~/.ssh/id_ed25519.pub --ttl 365d

# RUST
cargo install cargo-audit cargo-expand cargo-make cargo-tomlfmt cargo-tree cargo-udeps

# DOCKER DESKTOP
echo ''
echo 'System configuration complete!'
echo 'You will now be redirected to docker.com so you can download and install Docker '
echo 'Desktop.'

press_any_key_to_continue

open 'https://www.docker.com/products/docker-desktop'
