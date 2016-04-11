# DSE Vagrant Single Node
Simple Vagrant base project to install DataStax Enterprise (DSE) as a single node with optional Jupyter and other settings.

 The goal of this project is to enable a quick setup of DSE with ability to develop against and access a DSE server in a VM from the local box.

## Features
- Install and settings configured by single `config.yaml` file
- Includes DSE download script, just add DataStax username/password to config file
- Auto-installs Oracle JDK 1.8
- Once needed files (DSE, JDK) are downloaded future `vagrant up` commands will check for installers in `installers/` dir rather than redownloading
- Installs Jupyter for easy Notebook creation and sharing
- Easy to destroy and recreate a new VM w/ same settings

## Getting Started
### Prerequisites
- [Vagrant](http://vagrantup.com) installed
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) or other Vagrant compatible [VM service](https://www.vagrantup.com/docs/getting-started/providers.html)

### Steps
1) Clone Project
    ```
    git clone https://github.com/ibspoof/dse-vagrant-node.git
    ```

2) Edit `config.yaml` file with your DataStax account info and enable/disable wanted installs and configurations.

3) Vagrant up the box
    ```
    vagrant up
    ```

4) Use Vagrant image

    SSH Into box
    ```
    vagrant ssh
    ```

    or check out Jupyter notebooks:
    ```
    http://10.10.11.10:5000/
    ```

    or connect to C* using cqlsh:
    ```
    cqlsh 10.10.11.10
    ```

## Configuration
Most of the installation configuration can be found in the config.yaml file additional `cassandra.yaml` settings can be changed in `setup/cassandra/cassandra.temp.yaml`

### Defaults
- IP Address: 10.10.11.10
  - Can be acccessed from local machine i.e. `cqlsh 10.10.11.10`
- Jupyter Server: http://10.10.11.10:5000/
- Solr/Spark: disabled
- Cluster Name: DSE
- Snitch: GossipingPropertyFileSnitch
- DC: DC1


### Jupyter
If Jupyter is enabled it can be accessed at http://10.10.11.10:5000/ and configuration of nbextensions is at http://10.10.11.10:5000/nbextensions

### Customizing Installs
All setup files can be found in the `setup/` directory and named accordingly.  Other than the downloading of DSE unattended installer script which is Ruby all scripts are done in bash.

## Special Notes
- Inspired by Brian Cantoni's [vagrant-cassandra](https://github.com/bcantoni/vagrant-cassandra) project.
- Special thanks to Steven Lowenthal [@slowenthal](https://github.com/slowenthal) for his work on Jupyter kernals for [CQL](https://github.com/slowenthal/cql_kernel) and [DSE Spark](https://github.com/slowenthal/spark-kernel)
