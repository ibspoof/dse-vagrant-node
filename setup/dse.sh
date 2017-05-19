source /vagrant/setup/lib.sh
eval $(parse_yaml $YAML_FILE)

ETC_DSE="/etc/default/dse"
ETC_CASS_YAML="/etc/dse/cassandra/cassandra.yaml"
DS_AGENT="/var/lib/datastax-agent/conf/address.yaml"
DSE_VERSION=$(strip_comments ${vm_dse_install_version})
DSE_VERSION2=${DSE_VERSION:: -1}
DSE_INSTALLER_FILE=$(ls -t /vagrant/installers/*${DSE_VERSION2}*)
FILE_LIMIT_CONF="/etc/security/limits.d/cassandra.conf"

if [ "$(strip_comments $vm_dse_cassandra_seeds)" == "self" ]; then
    SEEDS=$(strip_comments ${vagrant_ip})
else
    SEEDS=$(strip_comments $vm_dse_cassandra_seeds)
fi

echo "Installing DSE..."

function install_dse {

    CLUSTER_NAME=$(strip_comments $vm_dse_cassandra_cluster_name)
    NUM_TOKENS=$(strip_comments $vm_dse_cassandra_num_tokens)
    IP=$(strip_comments ${vagrant_ip})

    chmod +x ${DSE_INSTALLER_FILE}

    ${DSE_INSTALLER_FILE} --mode unattended --update_system 0 \
        --seeds ${SEEDS} \
        --ring_name ${CLUSTER_NAME} \
        --interface ${IP} \
        --num_tokens ${NUM_TOKENS} \
        --start_services 0
        ## --cassandra_yaml_template ${SETUP_DIR}/cassandra/cassandra.temp.yaml
}

if [ -f $ETC_DSE ] && [ "$(strip_comments $vm_dse_force_reinstall)" == "true" ]; then
    install_dse
else
    install_dse
fi

# update cassandra.yaml
echo "Updating cassandra.yaml files.."
sed --follow-symlinks -i "s/endpoint_snitch: .*/endpoint_snitch: \"$(strip_comments $vm_dse_cassandra_snitch)\"/g" ${ETC_CASS_YAML}
sed --follow-symlinks -i "s/listen_address: .*/#listen_address: 0/g" ${ETC_CASS_YAML}
sed --follow-symlinks -i "s/# listen_interface: .*/listen_interface: eth1/g" ${ETC_CASS_YAML}
sed --follow-symlinks -i "s/rpc_address: .*/#rpc_address: 0/g" ${ETC_CASS_YAML}
sed --follow-symlinks -i "s/# rpc_interface: .*/rpc_interface: eth1/g" ${ETC_CASS_YAML}
sed --follow-symlinks -i "s/# memtable_cleanup_threshold: .*/memtable_cleanup_threshold: 0.5/g" ${ETC_CASS_YAML}

# enable spark
if [ "$(strip_comments $vm_dse_spark_enabled)" == "true" ]; then

    echo "Spark enabled in config, updating configurations..."

    sed --follow-symlinks -i 's/SPARK_ENABLED=.*/SPARK_ENABLED=1/g' ${ETC_DSE}

    echo "export SPARK_LOCAL_IP=\"$(strip_comments ${vagrant_ip})\"" | tee -a /tmp/${SPARK_CONFIG}
    echo "export SPARK_WORKER_CORES=\"$(strip_comments ${vm_dse_spark_worker_cores})\"" | tee -a /tmp/${SPARK_CONFIG}
    echo "export SPARK_WORKER_MEMORY=\"$(strip_comments ${vm_dse_spark_worker_memory})\"" | tee -a /tmp/${SPARK_CONFIG}

    mv /tmp/${SPARK_CONFIG} /etc/profile.d/${SPARK_CONFIG}
    sudo chown root:root /etc/profile.d/${SPARK_CONFIG}
fi

# Enable Solr
if [ "$(strip_comments $vm_dse_solr_enabled)" == "true" ]; then
    echo "Solr enabled in config, updating configurations..."
    sed --follow-symlinks -i 's/SOLR_ENABLED=.*/SOLR_ENABLED=1/g' ${ETC_DSE}
fi

# Enable Graph
if [ "$(strip_comments $vm_dse_graph_enabled)" == "true" ]; then
    echo "Graph enabled in config, updating configurations..."
    sed --follow-symlinks -i 's/GRAPH_ENABLED=.*/GRAPH_ENABLED=1/g' ${ETC_DSE}
fi

#echo "Setting limits to be friendly to DSE..."
#echo "cassandra         hard    nofile      500000" | tee -a ${FILE_LIMIT_CONF}
#echo "cassandra         soft    nofile      500000" | tee -a ${FILE_LIMIT_CONF}
#echo "cassandra         hard	memlock		128" | tee -a ${FILE_LIMIT_CONF}

echo deadline > /sys/block/sda/queue/scheduler
echo 8 > /sys/class/block/sda/queue/read_ahead_kb

#start dse service
if [ "$(strip_comments $vm_dse_start_services)" == "true" ]; then

    service dse start

    if [ "$(strip_comments $vm_dse_opscenter_agent_install)" == "true" ]; then
        service datastax-agent start
    fi
fi
