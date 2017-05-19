source /vagrant/setup/lib.sh
eval $(parse_yaml $YAML_FILE)

if [ "$(strip_comments $vm_studio_install)" == "false" ]; then
    return
fi

INSTALL_DIR="/opt/"
TAR=$(ls -t /vagrant/installers/*studio*.tar.gz)

tar -xf $TAR -C $INSTALL_DIR

INSTALLED_DIR=$(ls -td /opt/datastax-studio-*)
VAGRANT_IP=$(strip_comments ${vagrant_ip})
VAGRANT_PORT=$(strip_comments ${vm_studio_port})

# set local IP and Port from configs
sed --follow-symlinks -i "s/ httpBindAddress: .*/ httpBindAddress: ${VAGRANT_IP}/g" ${INSTALLED_DIR}/conf/configuration.yaml
sed --follow-symlinks -i "s/ httpPort: .*/ httpPort: ${VAGRANT_PORT}/g" ${INSTALLED_DIR}/conf/configuration.yaml

# set local IP in example connections
files=($INSTALLED_DIR/examples/connections/*)
for file in "${files[@]}"
do
    sed --follow-symlinks -i "s/\[\"127.0.0.1\"\]/[\"${VAGRANT_IP}\"]/g" $file
done

$INSTALLED_DIR/bin/server.sh > /dev/null 2>&1 &

echo "Finished installing DataStax Studio. To access visit http://${vagrant_ip}:${VAGRANT_PORT}"
