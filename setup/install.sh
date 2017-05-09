#!/bin/bash

source /vagrant/setup/lib.sh
eval $(parse_yaml $YAML_FILE)

# set timezone
echo ${vm_timezone} > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# install base files
echo "Installing required Ubuntu packages..."

apt-get update > /dev/null
apt-get install ${vm_ubuntu_install_packages} -y > /dev/null

if [ "$(strip_comments $vm_ubuntu_upgrade_packages)" == "true" ]; then
    echo "Upgrade ubuntu enabled, upgrading..."
    apt-get upgrade -y > /dev/null
fi

# install latest java
bash ${SETUP_DIR}/java.sh

# clean the house
apt-get autoremove -y
apt-get clean -y

if [ "$(strip_comments $vm_ubuntu_swap_disabled)" == "true" ]; then
    echo "Turning down swappiness..."
    echo 'vm.swappiness = 1' >> /etc/sysctl.conf
    echo 1 > /proc/sys/vm/swappiness
fi

# install DSE
bash ${SETUP_DIR}/dse.sh

# install cassandra python drivers
if [ "$(strip_comments $vm_ubuntu_cassandra_python_driver)" == "true" ]; then
    echo "Installing Python drivers for Cassandra. This takes a while..."
    pip install --quiet 'cassandra-driver'
fi

# install jupyter
if [ "$(strip_comments $vm_jupyter_enabled)" == "true" ]; then
    bash ${SETUP_DIR}/jupyter.sh
fi

# add cassandra to hosts
echo "$(strip_comments ${vagrant_ip}) cassandra" >> /etc/hosts

echo "Finished installing and configuring VM."
