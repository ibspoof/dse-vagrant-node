source /vagrant/setup/lib.sh

JDK_URL="http://download.oracle.com/otn-pub/java/jdk/8u77-b03/jdk-8u77-linux-x64.tar.gz"
COOKIE="Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie"
INSTALL_TAR="/vagrant/installers/jdk-8u77-linux-x64.tar.gz"
JDK_DIR="/opt/jdk1.8.0_77"
PROFILE_PATH="/etc/profile.d/java.sh"

function install_java {
    if [ ! -f ${INSTALL_TAR} ]; then
        echo "Oracle JDK tarball not found, downloading from Oracle..."
        wget --no-cookies --quiet --no-check-certificate -O ${INSTALL_TAR} --header "${COOKIE}" "${JDK_URL}"
    fi

    echo "Expanding JDK tarball and setting path location..."
    tar -xf ${INSTALL_TAR} -C /opt/

    # adding to every users startup
    echo "export JAVA_HOME=\"${JDK_DIR}\"" >> ${PROFILE_PATH}
    echo "export PATH=\"\$JAVA_HOME/bin:$PATH\"" >> ${PROFILE_PATH}
    chmod +x ${PROFILE_PATH}
    source ${PROFILE_PATH}

    ln -s ${JDK_DIR}/bin/java /bin/

    echo "Java successfully installed."
}

function install_java_apt {
    add-apt-repository ppa:webupd8team/java -y > /dev/null
    aptitude update -y > /dev/null
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
    aptitude install oracle-java8-installer -y > /dev/null
}

if hash java 2>/dev/null; then
    echo "Java installed skipping installation..."
else
    install_java
fi
