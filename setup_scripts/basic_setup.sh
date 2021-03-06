#!/usr/bin/env bash

# sudo apt edit-sources
# deb http://raspbian.raspberrypi.org/raspbian bullseye main contrib non-free rpi

echo "basic package"

if ( ! grep -q 'gitprompt.sh' ~/.bashrc ); then
  echo "install bash-git-prompt"

  cd ~
  git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt --depth=1

  echo "source ~/.bash-git-prompt/gitprompt.sh" >> ~/.bashrc
  echo "GIT_PROMPT_ONLY_IN_REPO=1" >> ~/.bashrc
  source ~/.bashrc

  echo "cleanup bash-git-prompt install"
  rm -rf ~/bash-git-prompt
fi

echo "Install TJ git-extras for nice extra git utilities"
curl -sSL http://git.io/git-extras-setup | sudo bash /dev/stdin

if ( ! grep -q 'plugin' ~/.vimrc ); then
  echo "improve vim"
  git clone git://github.com/brianleroux/quick-vim.git /tmp/quick-vim
  cd /tmp/quick-vim
  ./quick-vim install
  rm -rf /tmp/quick-vim
fi

echo "checking for alias reference in the ~/.bashrc"
if ( ! grep -q 'bash_alias' ~/.bashrc )
then
  echo "bashrc doesn't have reference to bash_aliases, put it in"
  echo "if [ -f ~/.bash_aliases ]; then source ~/.bash_aliases; fi" >> ~/.bashrc
fi

echo "installing rubies, pythons and javascripts"
sudo apt-get --yes --allow-unauthenticated install nodejs
sudo apt-get --yes --allow-unauthenticated install npm
sudo apt-get --yes --allow-unauthenticated install python
sudo apt-get --yes --allow-unauthenticated install python-pip
sudo apt-get --yes --allow-unauthenticated install ruby
sudo apt-get --yes --allow-unauthenticated install ruby-dev
sudo apt-get --yes --allow-unauthenticated install rubygems-integration
echo "done with rubies, javascripts and pythons"

echo "make npm up to date"
sudo npm install npm@latest -g

if [ ! -f ~/.npmrc ]; then
  echo "setup ~/.npmrc"
  touch ~/.npmrc
  echo "prefix=${HOME}/.node_modules" >> ~/.npmrc
  echo "python=/usr/bin/python" >> ~/.npmrc
fi

if [ ! -f ~/.gitconfig ]; then
  echo "setup ~/.gitconfig"
  cp ~/smile-pi/setup_files/.gitconfig ~/.gitconfig
fi

if [ ! -f ~/.bash_aliases ]; then
  echo "setup ~/.bash_aliases"
  cp ~/smile-pi/setup_files/.bash_aliases ~/.bash_aliases
fi
source ~/.bash_aliases

# need to reboot before installing compass
echo "install compass"
sudo gem install compass --no-ri --no-rdoc

#https://github.com/nodejs/node-gyp/issues/454
echo "install node-gyp"
sudo npm install -g node-gyp

echo "install nginx"
sudo apt-get --yes --allow-unauthenticated install nginx
echo "install fancyindex module for nginx"
sudo apt-get --yes --allow-unauthenticated install nginx-extras

echo "setup nginx conf files"

cd ~
git clone https://bitbucket.org/smileconsortium/smile_v2.git
cd smile_v2
git checkout -b plug origin/plug
sudo cp ~/smile_v2/vagrant/nginx.conf /etc/nginx/nginx.conf
sudo cp ~/smile_v2/vagrant/proxy.conf /etc/nginx/proxy.conf
#https://stackoverflow.com/questions/584894/sed-scripting-environment-variable-substitution
#https://askubuntu.com/questions/20414/find-and-replace-text-within-a-file-using-commands
sudo sed -i 's@/vagrant@'"$HOME"/smile_v2/frontend/src'@' /etc/nginx/nginx.conf
sudo sed -i 's@/couchdb/(.*)      /$1  break;@/couchdb/(.*)      /smile/$1  break;@' /etc/nginx/nginx.conf
sudo sed -i 's@/couchdb           /    break;@/couchdb           /smile    break;@' /etc/nginx/nginx.conf

cd ~/smile-pi/setup_files/
sudo cp -rf etc_hosts /etc/hosts
echo "hosts file overwritten"

# To address nginx permissions issue, $HOME/smile_v2/frontend/src/ accessibility
sudo chmod +755 $HOME

echo "systemctl for nginx"
sudo systemctl enable nginx
sudo systemctl stop nginx
sudo systemctl start nginx

cd; cd -
cd ~/smile-pi
