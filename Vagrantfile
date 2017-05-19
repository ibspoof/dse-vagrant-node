# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require './setup/downloader'

config = YAML.load_file('config.yaml')
vSettings = config['vagrant']
tasksForInstall = ['up', 'provision']

if tasksForInstall.include? ARGV[0]
  ## download installers
  downloader = Downloader.new(config)
  downloader.downloadDSE()
  downloader.downloadStudio()
end


Vagrant.configure(2) do |config|

  config.vm.box = vSettings['base_vm']

  config.vm.define vSettings['name'] do |dse|

        dse.vm.provider :virtualbox do |v|
            v.customize ["modifyvm", :id, "--memory", vSettings['memory_size']]
            v.customize ["modifyvm", :id, "--cpuexecutioncap", vSettings['exec_cap']]
            v.cpus = vSettings['cpus']
        end

        config.vm.hostname = vSettings['hostname']
        config.vm.network "private_network", ip: vSettings['ip']

        config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
        config.vm.provision :shell, :path => "./setup/install.sh"
  end

end
