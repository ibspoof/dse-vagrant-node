INSTALL_DIR=/vagrant/installers

# install sbt
sudo dpkg -i ${INSTALL_DIR}/sbt-0.13.11.deb
sudo apt-get install -f
sudo apt-get install sbt

# install apache spark

sudo dpkg -i ${INSTALL_DIR}/scala-2.11.8.deb
sudo apt-get install -f
sudo apt-get install scala
