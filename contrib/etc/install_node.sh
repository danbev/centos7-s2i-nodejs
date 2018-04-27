#!/bin/bash

set -ex

git_version=2.17.0
git_dir=/usr/local/git
wget -q https://mirrors.edge.kernel.org/pub/software/scm/git/git-${git_version}.tar.gz
tar xzf git-${git_version}.tar.gz
pushd git-${git_version}
make -s prefix=${git_dir} all install
popd
rm -rf git-${git_version} git-${git_version}.tar.gz

echo "export PATH=${git_dir}/bin:$PATH" >> /etc/bashrc
export PATH=${git_dir}/bin:$PATH
echo "done installing git:"
git --version
mkdir -p /usr/local/git/etc/
touch /usr/local/git/etc/gitconfig

# Ensure git uses https instead of ssh for NPM install
# See: https://github.com/npm/npm/issues/5257
echo -e "Setting git config rules"
git config --system url."https://github.com".insteadOf git@github.com:
git config --global url."https://github.com".insteadOf ssh://git@github.com
git config --system url."https://".insteadOf git://
git config --system url."https://".insteadOf ssh://
git config --list

yum install -y --setopt=tsflags=nodocs openssl
yum install -y https://github.com/bucharest-gold/node-rpm/releases/download/v${NODE_VERSION}/rhoar-nodejs-${NODE_VERSION}-1.el7.centos.x86_64.rpm
yum install -y https://github.com/bucharest-gold/node-rpm/releases/download/v${NODE_VERSION}/npm-${NPM_VERSION}-1.${NODE_VERSION}.1.el7.centos.x86_64.rpm

# Install yarn
npm install -g yarn -s &>/dev/null

# Make sure npx is available
if [ ! -h /usr/bin/npx ] ; then
  ln -s /usr/lib/node_modules/npm/bin/npx-cli.js /usr/bin/npx
fi

# Make /opt/app-root owned by user 1001
chown -R 1001:0 /opt/app-root
chmod -R ug+rwx /opt/app-root

# Fix permissions for the npm update-notifier
chmod -R 777 /opt/app-root/src/.config

# Delete NPM things that we don't really need (like tests) from node_modules
find /usr/local/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf

# Clean up the stuff we downloaded
yum clean all -y
