source /vagrant/setup/lib.sh
eval $(parse_yaml $YAML_FILE)

if [ "$(strip_comments $vm_dse_opscenter_agent_install)" == "false" ]; then
    exit
fi

AGENT_INSTALL_FILE=$(ls -t /vagrant/installers/*agent*.deb)
AGENT_CONF=/var/lib/datastax-agent/conf/address.yaml

# Setup data-stax agent
if [ "$(strip_comments $vm_dse_opscenter_agent_opcenter_ip)" == "vmhost" ]; then
    OPSC_IP=$(netstat -rn | sed -n 3p | awk '{print $2}')
else
    OPSC_IP=$(strip_comments $vm_dse_opscenter_agent_opcenter_ip)
fi

dpkg -i $AGENT_INSTALL_FILE
apt-get install -f

sed --follow-symlinks -i "s/# stomp_interface: .*/stomp_interface: ${OPSC_IP}/g" ${AGENT_CONF}
echo "listen_interface: $(strip_comments ${vagrant_ip})" | tee -a ${AGENT_CONF}

service datastax-agent start
