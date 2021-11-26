#!/usr/bin/env bash
set -xeuo pipefail

# Installs the porter CLI for a single user.
# PORTER_HOME:      Location where Porter is installed (defaults to ~/.porter).
# PORTER_MIRROR:       Base URL where Porter assets, such as binaries and atom feeds, are downloaded. This lets you
#                   setup an internal mirror.
# PORTER_PERMALINK: The version of Porter to install, such as vX.Y.Z, latest or canary.
# PKG_PERMALINK:    The version of mixins and plugins to install, such as latest or canary.

export PORTER_HOME=${PORTER_HOME:-~/.porter}
export PORTER_MIRROR=${PORTER_MIRROR:-https://cdn.porter.sh}
PORTER_PERMALINK=${PORTER_PERMALINK:-v0.38.8}
PKG_PERMALINK=${PKG_PERMALINK:-latest}

echo "Installing porter@$PORTER_PERMALINK to $PORTER_HOME from $PORTER_MIRROR"

mkdir -p $PORTER_HOME/runtimes

curl -fsSLo $PORTER_HOME/porter $PORTER_MIRROR/$PORTER_PERMALINK/porter-linux-amd64
chmod +x $PORTER_HOME/porter
cp $PORTER_HOME/porter $PORTER_HOME/runtimes/porter-runtime
echo Installed `$PORTER_HOME/porter version`

$PORTER_HOME/porter mixin install exec --version $PKG_PERMALINK

echo "Installation complete."
echo "Add porter to your path by adding the following line to your ~/.profile and open a new terminal:"
echo "export PATH=\$PATH:~/.porter"
