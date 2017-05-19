# DSE Vagrant Single Node
Simple Vagrant base project to install DataStax Enterprise (DSE) 5.1 as a single node with optional DataStax Studio and other settings.

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
**1) Clone Project**
```
git clone https://github.com/ibspoof/dse-vagrant-node.git
```

**2) Edit `config.yaml` file with your DataStax account info and enable/disable wanted installs and configurations.**

**3) Vagrant up the box**
```
vagrant up
```

**4) Use**

SSH Into box
```
vagrant ssh
```

or check out DataStax Studio:
```
http://10.10.10.10:9109
```

or connect to C* using cqlsh:
```
cqlsh 10.10.10.10
```

or once sshed in cqlsh:
```
cqlsh 10.10.10.10  or  cqlsh casssandra
```

## Configuration
Installation configuration can be found in the `config.yaml` file

### Defaults
- IP Address: 10.10.11.10
  - Can be acccessed from local machine i.e. `cqlsh 10.10.10.10`
- DataStax Studio 2.0: http://10.10.10.10:9091/
- Solr/Spark/Graph: disabled
- Cluster Name: DSE
- Snitch: GossipingPropertyFileSnitch
- DC: DC1
- OpsCenter Agent: disabled

### Customizing Installs
All setup files can be found in the `setup/` directory and named accordingly.  Other than the downloading of DSE unattended installer script which is Ruby all scripts are done in bash.

## Special Notes
- Inspired by Brian Cantoni's [vagrant-cassandra](https://github.com/bcantoni/vagrant-cassandra) project.
