#!/bin/bash

source /vagrant/setup/lib.sh
eval $(parse_yaml $YAML_FILE)

# set timezone
echo ${vm_timezone} > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# install base files
echo "Installing required Ubuntu packages..."

apt-get update > /dev/null
apt-get install wget ${vm_ubuntu_install_packages} -y > /dev/null

if [ "$(strip_comments $vm_ubuntu_upgrade_packages)" == "true" ]; then
    echo "Upgrade ubuntu enabled, upgrading..."
    apt-get upgrade -y > /dev/null
fi

# install latest java
if [[ "${jdk_provider}" == "oracle_jdk"* ]]; then
  echo "Installing Oracle Java"
  bash ${SETUP_DIR}/java.sh
else
  echo "Adding backport repro"
  add-apt-repository ppa:openjdk-r/ppa
  apt-get update 
  echo "Installing OpenJDK-8"
  apt-get install openjdk-8-jdk -y > /dev/null
fi

# clean the house
apt-get autoremove -y
apt-get clean -y

if [ "$(strip_comments $vm_ubuntu_swap_disabled)" == "true" ]; then
    echo "Turning down swappiness..."
    echo 'vm.swappiness = 1' | tee -a /etc/sysctl.conf
    echo 'vm.max_map_count = 1048575' | tee -a /etc/sysctl.conf
    echo 1 | tee /proc/sys/vm/swappiness

    swapoff --all
    sysctl -p
fi

# install DSE
bash ${SETUP_DIR}/dse.sh

# install studio
bash ${SETUP_DIR}/studio.sh

# install opscenter agent
bash ${SETUP_DIR}/ops_agent.sh

# install cassandra python drivers
if [ "$(strip_comments $vm_ubuntu_cassandra_python_driver)" == "true" ]; then
    echo "Installing Python drivers for Cassandra. This takes a while..."
    pip install --quiet 'cassandra-driver==2.7.2'
fi

# add cassandra to hosts
echo "$(strip_comments ${vagrant_ip}) cassandra" | tee -a /etc/hosts

echo "Finished installing and configuring VM."
