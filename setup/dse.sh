source /vagrant/setup/lib.sh
eval $(parse_yaml $YAML_FILE)

ETC_DSE="/etc/default/dse"
ETC_CASS_YAML="/usr/share/dse/resources/cassandra/conf/cassandra.yaml"
SOLR_SERVER_XML="/usr/share/dse/resources/tomcat/conf/server.xml"
DS_AGENT="/var/lib/datastax-agent/conf/address.yaml"
DSE_INSTALLER_FILE="$(ls /vagrant/installers | grep $(strip_comments ${vm_dse_install_version}))"

echo "Installing DSE..."

function install_dse {

    if [ "$(strip_comments $vm_dse_cassandra_seeds)" == "self" ]; then
        SEEDS=$(strip_comments ${vagrant_ip})
    else
        SEEDS=$(strip_comments $vm_dse_cassandra_seeds)
    fi

    chmod +x ${INSTALL_DIR}/${DSE_INSTALLER_FILE}
    ${INSTALL_DIR}/${DSE_INSTALLER_FILE} --mode unattended --update_system 0 \
        --seeds ${SEEDS} --interface $(strip_comments ${vagrant_ip}) \
        --start_services 0 --cassandra_yaml_template ${SETUP_DIR}/cassandra/cassandra.temp.yaml
}

if [ -f $ETC_DSE ]; then
    if [ "$(strip_comments $vm_dse_force_reinstall)" == "true" ]; then
        install_dse
    fi
else
    install_dse
fi

# update cassandra.yaml
echo "Updating cassandra.yaml files.."
sed -i "s/cluster_name: .*/cluster_name: \"$(strip_comments $vm_dse_cassandra_cluster_name)\"/g" ${ETC_CASS_YAML}
sed -i "s/endpoint_snitch: .*/endpoint_snitch: \"$(strip_comments $vm_dse_cassandra_snitch)\"/g" ${ETC_CASS_YAML}
sed -i "s/num_tokens: .*/num_tokens: $(strip_comments $vm_dse_cassandra_num_tokens)/g" ${ETC_CASS_YAML}


# Setup data-stax agent
if [ "$(strip_comments $vm_dse_agent_opcenter_ip)" == "vmhost" ]; then
    OPSC_IP=$(netstat -rn | sed -n 3p | awk '{print $2}')
else
    OPSC_IP=$(strip_comments $vm_dse_agent_opcenter_ip)
fi

sed -i "s/stomp_interface: .*/stomp_interface: \"${OPSC_IP}\"/g" ${DS_AGENT}
echo "listen_address: ${vagrant_ip}" >> ${DS_AGENT}


# enable solr
if [ "$(strip_comments $vm_dse_solr_enabled)" == "true" ]; then

    echo "Spark enabled in config, updating configurations..."

    sed -i 's/SOLR_ENABLED=.*/SOLR_ENABLED=1/g' ${ETC_DSE}
fi

# enable spark
if [ "$(strip_comments $vm_dse_spark_enabled)" == "true" ]; then

    echo "Spark enabled in config, updating configurations..."

    SPARK_CONFIG="spark_config.sh"

    sed -i 's/SPARK_ENABLED=.*/SPARK_ENABLED=1/g' ${ETC_DSE}

    echo "export SPARK_LOCAL_IP=\"$(strip_comments ${vagrant_ip})\"" > /tmp/${SPARK_CONFIG}
    echo "export SPARK_WORKER_CORES=\"$(strip_comments ${vm_dse_spark_worker_cores})\"" >> /tmp/${SPARK_CONFIG}
    echo "export SPARK_WORKER_MEMORY=\"$(strip_comments ${vm_dse_spark_worker_memory})\"" >> /tmp/${SPARK_CONFIG}

    mv /tmp/${SPARK_CONFIG} /etc/profile.d/${SPARK_CONFIG}
    sudo chown root:root /etc/profile.d/${SPARK_CONFIG}
fi

#start dse service
if [ "$(strip_comments $vm_dse_start_services)" == "true" ]; then
    /etc/init.d/dse start
    /etc/init.d/datastax-agent start
fi
