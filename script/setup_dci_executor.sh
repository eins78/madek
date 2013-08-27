#!/bin/bash

################################################################
# Notes
# 
# This is a docix setup script for Debian wheezy, Ubuntu 12.04
# and madek.
# This script is idempotent and it must be kept this way! 
# 
# example of invocation (as root):
#
# curl https://raw.github.com/zhdk/madek/next/script/setup_docix_slave.sh | bash -l
#
################################################################




#############################################################
# remove the halfwitted stuff
#############################################################
rm -rf /etc/profile.d/rvm.sh 
rm -rf /usr/local/rvm/

#############################################################
# update
#############################################################
apt-get update

#############################################################
# Adapt to our environment
#############################################################
apt-get install --assume-yes lsb_release
if [ `lsb_release -is` == "Debian" ] 
then MOZILLA_BROWSER=iceweasel
else MOZILLA_BROWSER=firefox
fi

#############################################################
# fix broken debian/ubuntu locale
#############################################################

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
apt-get install --assume-yes locales
dpkg-reconfigure locales

cat << 'EOF' > /etc/profile.d/locale.sh 
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
EOF

#############################################################
# upgrade and install basic stuff
#############################################################
apt-get dist-upgrade --assume-yes
apt-get install --assume-yes curl openssh-server openjdk-7-jdk unzip zip

#############################################################
# setup ntp for zhdk
#############################################################
apt-get install --assume-yes ntp ntpdate
service ntp stop
ntpdate ntp.zhdk.ch
cat << 'EOF' > /etc/ntp.conf
driftfile /var/lib/ntp/ntp.drift
statsdir /var/log/ntpstats/
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable
server ntp.zhdk.ch
EOF
service ntp start

#############################################################
# ssh server and root access
#############################################################
chmod go-w ~/
mkdir -p ~/.ssh
chmod go-w $HOME $HOME/.ssh
cat << 'EOF' > ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA4Dn7DJZ923mketufL52fibawVVwEisSZAaeMA4qt2VYALMd37i8Hx5nP/d9FyCbIfiDj0GRcpLgKSgZrGRwX1UxkOAzYnzDFnY2gm2VjgIwV5Ryf5z4dbCvfxz2i9rpxM8lK2/iTDglxb9z2fBbwC+0WnhbeKy2+UusZjioE49U= rca@nomad ssh-rsa
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxjIL2YhVqNXwDzzubbUuf839VUxo3gbelVqcifJw8EWfmzihDa80VXY6snamHdt3LmSOKc0BXbEVFD3GuehqUi+gjvRl7RE/YgQt9LjOyJAFzZRh+5XbQ+QCYrfdF8NdrlYv6qmGnTK2U0/SiHObc5qWLNVqdCUPY2AVg9/19PjtiaLxd74so1ApzgxzIubzw5WEdxd16pFvlcO6jmewwgjfTNa9hA9U6C9zCtX/KLiESmTpQIYAX9KB8hRbWM9vMmjR8mUymJeJYaEWRSEFlQz0kqYo3PRkLAs8vsuFhZUs5IVFx0Saig9MOgL1x5h/4UAtvGj3M20mG7/3wimtbw== thomas@macbook
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC26PJTohUjHaIMy6srYXywXzlZHsKSV7OhorlSiCjV9MUVX+EbzhCPcqpT0kc7A2VgyCjbvWI6Zi3dD1/ynvODligfMMN3IBsgBL9h9uC/FmcfAmRTPPNaqjiAFBc5n+j7DrFtondrkGdCg39+UUuGmyup6rIbKYbxq2F7mU0qEHLnItPLZAl+sdJGPCRKj3jIed+zRhPSHBkZn8aa2WfEjZO8JpOt66fLAey6SW86rP+z78m9BjsTXs13IPkqBbaU27Ek1nVhPMdX1u3vsK5UIaKb2nSWOESJRUDW8U4JKtf0PDpTbILTNeNoXJkVIMJLvqY1PXRSFszB3/JajGa3 email@sebastianpape.com
EOF
chmod 600 $HOME/.ssh/authorized_keys
chown `whoami` $HOME/.ssh/authorized_keys

#############################################################
# editor
#############################################################
apt-get install --assume-yes vim-nox
update-alternatives --set editor /usr/bin/vim.nox


#############################################################
# add docix user
#############################################################
adduser --disabled-password -gecos "" docix
cat << 'DOCIX' | su -l docix
  mkdir ~/bin
DOCIX

#############################################################
# add ~/bin to the PATH
#############################################################
cat << 'EOF' > /etc/profile.d/user_bin.sh 
if [ -d "$HOME/bin" ] ; then
  PATH="$HOME/bin:$PATH"
fi
EOF

#############################################################
# PostgreSQL (mostly for Madek)
#############################################################
apt-get install --assume-yes  postgresql postgresql-client libpq-dev postgresql-contrib
sed -i 's/peer/trust/g' /etc/postgresql/9.1/main/pg_hba.conf
sed -i 's/md5/trust/g' /etc/postgresql/9.1/main/pg_hba.conf
/etc/init.d/postgresql restart
cat << 'EOF' | psql -U postgres
CREATE USER DOCIX PASSWORD 'docix' superuser createdb login;
CREATE DATABASE docix;
GRANT ALL ON DATABASE docix TO docix;
EOF

#############################################################
# MySQL (mostly for leihs)
#############################################################
DEBIAN_FRONTEND=noninteractive apt-get install -q --assume-yes mysql-server libmysqlclient-dev 
mysql -uroot -e "grant all privileges on *.* to docix@localhost identified by 'docix';"


###########################################################
# phantomjs 1.9
###########################################################
cat << 'EOF' | su -l 
cd /tmp 
rm -rf phantomjs-1.7.0-linux-x86_64
rm -rf phantomjs-1.9.0-linux-x86_64
EOF

cat << 'DOCIX' | su -l docix
cd /tmp 
curl https://phantomjs.googlecode.com/files/phantomjs-1.9.0-linux-x86_64.tar.bz2 | tar xj
cp phantomjs-1.9.0-linux-x86_64/bin/phantomjs ~/bin/
DOCIX


#############################################################
# chromium
#############################################################

if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
cat << 'EOF' | su -l 
apt-get update
apt-get purge --assume-yes google-chrome-stable
rm /etc/apt/sources.list.d/google.list
apt-get update
apt-get install --assume-yes chromium-browser
EOF
fi

#############################################################
# chromedriver
#############################################################

cat << 'EOF' | su -l 
cd /tmp 
rm -rf chromedriver*
EOF 

cat << 'DOCIX' | su -l docix
cd /tmp 
curl https://chromedriver.googlecode.com/files/chromedriver_linux64_26.0.1383.0.zip > chromedriver.zip
unzip chromedriver.zip
mv chromedriver ~/bin
DOCIX


###########################################################
# leinigen 
###########################################################

cat << 'DOCIX' | su -l docix
curl https://raw.github.com/technomancy/leiningen/stable/bin/lein > ~/bin/lein
chmod a+x ~/bin/lein
lein
DOCIX


###########################################################
# prepare rbenv, ruby and ...
###########################################################

apt-get install --assume-yes git x11vnc xvfb zlib1g-dev \
  libssl-dev libxslt1-dev libxml2-dev build-essential \
  libimage-exiftool-perl imagemagick $MOZILLA_BROWSER libreadline-dev libreadline6 libreadline6-dev \
  g++

cat << 'EOF' > /etc/profile.d/rbenv.sh
# rbenv
if [ -d $HOME/.rbenv ]; then
function load_rbenv {
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init -)"
}
function unload_rbenv(){
export PATH=`ruby -e "puts ENV['PATH'].split(':').reject{|s| s.match(/\.rbenv/)}.join(':')"`
}
# load_rbenv
fi
EOF


###########################################################
# docix user and rbenv rubies
###########################################################
cat << 'DOCIX' | su -l docix
curl https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash
load_rbenv
rbenv update
DOCIX

cat << 'DOCIX' | su -l docix
load_rbenv

rbenv install jruby-1.7.4
rbenv shell jruby-1.7.4
gem install bundler
gem update --system
gem install rubygems-update
rbenv rehash
gem install bundler
rbenv rehash

rbenv install 1.9.3-p448
rm ~/.rbenv/versions/ruby-1.9.3
ln -s  ~/.rbenv/versions/1.9.3-p448/ ~/.rbenv/versions/ruby-1.9.3
rbenv shell 1.9.3-p448
rbenv rehash
gem update --system
gem install rubygems-update
rbenv rehash
update_rubygems
gem install bundler
rbenv rehash

rbenv install 2.0.0-p247
rm ~/.rbenv/versions/ruby-2.0.0
ln -s  ~/.rbenv/versions/2.0.0-p247/ ~/.rbenv/versions/ruby-2.0.0
rbenv shell 2.0.0-p247
rbenv rehash
gem update --system
gem install rubygems-update
rbenv rehash
update_rubygems
gem install bundler
rbenv rehash

rbenv global ruby-2.0.0 

DOCIX


###########################################################
# gherkin lexer so we can run it under plain ruby
###########################################################

apt-get install --assume-yes ragel

cat << 'DOCIX' | su -l docix
rbenv shell ruby-1.9.3 
gem install gherkin -v 2.12.0
cd ~/.rbenv/versions/ruby-1.9.3/lib/ruby/gems/1.9.1/gems/gherkin-2.12.0/ 
bundle install
rbenv rehash
bundle exec rake compile:gherkin_lexer_en
DOCIX



###########################################################
# docix login stuff
###########################################################


# ssh
cat << 'DOCIX' | su -l docix
chmod go-w ~/
mkdir -p ~/.ssh
chmod go-w $HOME $HOME/.ssh
cat << 'EOF' > ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA4Dn7DJZ923mketufL52fibawVVwEisSZAaeMA4qt2VYALMd37i8Hx5nP/d9FyCbIfiDj0GRcpLgKSgZrGRwX1UxkOAzYnzDFnY2gm2VjgIwV5Ryf5z4dbCvfxz2i9rpxM8lK2/iTDglxb9z2fBbwC+0WnhbeKy2+UusZjioE49U= rca@nomad ssh-rsa
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxjIL2YhVqNXwDzzubbUuf839VUxo3gbelVqcifJw8EWfmzihDa80VXY6snamHdt3LmSOKc0BXbEVFD3GuehqUi+gjvRl7RE/YgQt9LjOyJAFzZRh+5XbQ+QCYrfdF8NdrlYv6qmGnTK2U0/SiHObc5qWLNVqdCUPY2AVg9/19PjtiaLxd74so1ApzgxzIubzw5WEdxd16pFvlcO6jmewwgjfTNa9hA9U6C9zCtX/KLiESmTpQIYAX9KB8hRbWM9vMmjR8mUymJeJYaEWRSEFlQz0kqYo3PRkLAs8vsuFhZUs5IVFx0Saig9MOgL1x5h/4UAtvGj3M20mG7/3wimtbw== thomas@macbook
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC26PJTohUjHaIMy6srYXywXzlZHsKSV7OhorlSiCjV9MUVX+EbzhCPcqpT0kc7A2VgyCjbvWI6Zi3dD1/ynvODligfMMN3IBsgBL9h9uC/FmcfAmRTPPNaqjiAFBc5n+j7DrFtondrkGdCg39+UUuGmyup6rIbKYbxq2F7mU0qEHLnItPLZAl+sdJGPCRKj3jIed+zRhPSHBkZn8aa2WfEjZO8JpOt66fLAey6SW86rP+z78m9BjsTXs13IPkqBbaU27Ek1nVhPMdX1u3vsK5UIaKb2nSWOESJRUDW8U4JKtf0PDpTbILTNeNoXJkVIMJLvqY1PXRSFszB3/JajGa3 email@sebastianpape.com
EOF
chmod 600 $HOME/.ssh/authorized_keys
chown `whoami` $HOME/.ssh/authorized_keys
DOCIX
