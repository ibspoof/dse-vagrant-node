source /vagrant/setup/lib.sh
eval $(parse_yaml $YAML_FILE)

JUPYTER_ETC="/etc/jupyter"
DSE_KERNEL_URL="https://github.com/slowenthal/spark-kernel/releases/download/0.1.4.5-cassandra/kernel-0.1.4.5-cassandra.tgz"
DSE_KERNEL_DIR="kernel-0.1.4.5-cassandra"
JUPYTER_CONF_DIR="/root/.jupyter/nbconfig"
NB_EXT_GIT_URL="https://github.com/ipython-contrib/IPython-notebook-extensions.git"
JUPYTER_INITD="/etc/init.d/jupyter"


function install_jupyter {
    echo "Installing jupyter and cores..."

    #install jupyter
    pip install --quiet jupyter

    #setup config details
    mkdir ${JUPYTER_ETC}

    cat <<EOF > ${JUPYTER_ETC}/jupyter_notebook_config.py
c.NotebookApp.ip = '$(strip_comments ${vagrant_ip})'
c.NotebookApp.port = $(strip_comments ${vm_jupyter_port})
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '/vagrant/notebooks/'
EOF

    # move default configs to
    mkdir -p ${JUPYTER_CONF_DIR}
    cp ${SETUP_DIR}/jupyter/*.json ${JUPYTER_CONF_DIR}/

    # install init.d file
    cp ${SETUP_DIR}/jupyter/jupyter /etc/init.d/
    chmod +x /etc/init.d/jupyter

    # add jupyter to startup
    update-rc.d jupyter defaults

    # stop process JIC
    /etc/init.d/jupyter stop

    # install jupyter notebooks
    echo "Installing extra extensions for jupyter..."
    pip install --quiet psutil --upgrade
    mkdir -p /root/.local/share/jupyter
    git clone ${NB_EXT_GIT_URL} /tmp/IPython-notebook-extensions
    cd /tmp/IPython-notebook-extensions && python setup.py -q install

    # install cql kernel
    echo "Installing cql kernal for jupyter. This can take a while..."
    pip install --quiet cql_kernel
    python -m cql_kernel.install ${vagrant_ip}

    # if spark is enabled install the spark kernal that works with DataStaxEnterprise
    if [ "$(strip_comments $vm_dse_spark_enabled)" == "true" ]; then
        echo "Installing Spark jupyter core..."
        wget --quiet -P /root/ ${DSE_KERNEL_URL}
        cd /root
        tar -xvf ${DSE_KERNEL_DIR}.tgz
        ${DSE_KERNEL_DIR}/bin/setup.sh [${vagrant_ip}]
    fi

    # start jupyter
    /etc/init.d/jupyter start

}


if [ ! -f $JUPYTER_INITD ]; then
    install_jupyter
fi
