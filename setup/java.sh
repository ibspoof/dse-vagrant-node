source /vagrant/setup/lib.sh

function install_oracle_jdk {

    JDK_VERSION="8u131"
    JDK_BUILD="b11"
    ## see https://gist.github.com/P7h/9741922 for latest version links
    JDK_URL="http://download.oracle.com/otn-pub/java/jdk/${JDK_VERSION}-${JDK_BUILD}/d54c1d3a095b4ff2b6607d096fa80163/jdk-${JDK_VERSION}-linux-x64.tar.gz"
    COOKIE="Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie"
    INSTALL_TAR="/vagrant/installers/jdk-${JDK_VERSION}-linux-x64.tar.gz"
    INSTALL_TAR_SIZE=$(stat --printf="%s" $INSTALL_TAR)
    PROFILE_PATH="/etc/profile.d/java.sh"

    if [ ! -f ${INSTALL_TAR} ]; then
        echo "Oracle JDK tarball not found, downloading from Oracle..."
        wget --quite --no-cookies --no-check-certificate -O ${INSTALL_TAR} --header "${COOKIE}" "${JDK_URL}"
    fi

    if [ "${INSTALL_TAR_SIZE}" -lt "500" ]; then
        echo "Oracle JDK tarball not valid, re-downloading from Oracle..."
        wget --quite --no-cookies --no-check-certificate -O ${INSTALL_TAR} --header "${COOKIE}" "${JDK_URL}"
    fi

    echo "Expanding JDK tarball and setting path location..."
    tar -xf ${INSTALL_TAR} -C /opt/

    JDK_DIR=$(ls -td /opt/jdk*)

    # adding to every users startup
    echo "export JAVA_HOME=\"${JDK_DIR}\"" >> ${PROFILE_PATH}
    echo "export PATH=\"\$JAVA_HOME/bin:$PATH\"" >> ${PROFILE_PATH}
    chmod +x ${PROFILE_PATH}
    source ${PROFILE_PATH}

    rm -rf /bin/java
    ln -s ${JDK_DIR}/bin/java /bin/java
}

function install_open_jdk {
    echo "Adding backport repo..."
    add-apt-repository ppa:openjdk-r/ppa 2> /dev/null
    apt-get update 2> /dev/null

    echo "Installing OpenJDK v8..."
    apt-get install openjdk-8-jdk -y > /dev/null
    update-alternatives --config java >/dev/null
    update-alternatives --config javac >/dev/null
}


if hash java 2>/dev/null; then
    echo "Java installed skipping installation..."
else
    if [[ "${vm_ubuntu_java_jdk_provider}" == "open_jdk" ]]; then
        install_open_jdk
    else
        install_oracle_jdk
    fi

    echo "Java successfully installed."
fi
