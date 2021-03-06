# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Use this Vagrantfile to standup the Baribican network
#

Vagrant.configure("2") do |config|

  config.vm.box = "centos-6.5"
  config.vm.box_url = "https://ca9f9b62ae1b1e47c4f8-989e703834df24142dff402333777a7c.ssl.cf1.rackcdn.com/centos-6.5-provisionerless.box"

  # Define individual nodes:
  ip_api = "192.168.50.4"
  ip_worker = "192.168.50.6"
  ip_db = "192.168.50.17"
  ip_repose = "192.168.50.19"

  # Define the queue cluster:
  cluster_queue_name = "queue_cluster_1_2_3"
  nodes_queue = [
    { :vmname => 'barbican_queue_1', :hostname => 'barbican-queue-test-1', :ip => '192.168.50.8'},
    { :vmname => 'barbican_queue_2', :hostname => 'barbican-queue-test-2', :ip => '192.168.50.9'},
    #{ :vmname => 'barbican_queue_3', :hostname => 'barbican-queue-test-3', :ip => '192.168.50.10'}
  ]

  nodes_queue.each do |node|
    config.vm.define node[:vmname] do |barbican_queue|
      barbican_queue.vm.hostname = node[:hostname]

      barbican_queue.vm.network :private_network, ip: node[:ip], :netmask => "255.255.0.0"
      #barbican_queue.vm.network :forwarded_port, guest: 22, host: 2208, auto_correct: true
      #barbican_queue.vm.network :forwarded_port, guest: 80, host: 8008, auto_correct: true
      barbican_queue.vm.network :forwarded_port, guest: 15672, host: 15672, auto_correct: true

      # Provision the node.
      barbican_queue.vm.provision :chef_solo do |chef|
        chef.arguments = '-l debug'
        chef.roles_path = "roles"
        chef.data_bags_path = 'data_bags'
        chef.run_list = [
          "role[barbican-queue]",
        ]
        chef.json = {
          "solo_ips" => nodes_queue,
          "rabbitmq" => {
              "cluster" => true,
              "erlang_cookie" => "#{cluster_queue_name}"
          },
        }
      end
    end
  end

  config.vm.define :dbsimple do |dbsimple|
    dbsimple.vm.hostname = "db-simple"
    dbsimple.vm.network :private_network, ip: "#{ip_db}", :netmask => "255.255.0.0"
    dbsimple.vm.network :forwarded_port, guest: 22, host: 2217, auto_correct: true
    dbsimple.vm.network :forwarded_port, guest: 5432, host: 5432
    dbsimple.vm.network :forwarded_port, guest: 80, host: 8017
    dbsimple.vm.provision :chef_solo do |chef|
      chef.roles_path = "roles"
      chef.data_bags_path = 'data_bags'
      chef.json = {
                    "postgresql" => {
                        'pg_hba' => [
                          {
                            'comment' => '# "local" is for Unix domain socket connections only',
                            'type' => 'local', 
                            'db' => 'all',
                            'user' => 'postgres', 
                            'addr' => nil,
                            'method' => 'ident'
                          },
                          {
                            'type' => 'local', 
                            'db' => 'all',
                            'user' => 'all', 
                            'addr' => nil,
                            'method' => 'ident'
                          },
                          {
                            'comment' => '# Open external comms with database',
                            'type' => 'host', 
                            'db' => 'all',
                            'user' => 'all', 
                            'addr' => '10.0.2.2/32',
                            'method' => 'trust'
                          },
                          {
                            'comment' => '# Open comms with the api node',
                            'type' => 'host', 
                            'db' => 'all',
                            'user' => 'all', 
                            'addr' => '192.168.50.0/24',
                            'method' => 'trust'
                          },
                          {
                            'comment' => '# Open comms with the api node',
                            'type' => 'host', 
                            'db' => 'all',
                            'user' => 'all', 
                            'addr' => '192.168.50.4/32',
                            'method' => 'trust'
                          },
                          {
                            'comment' => '# Open comms with the worker node',
                            'type' => 'host', 
                            'db' => 'all',
                            'user' => 'all', 
                            'addr' => '192.168.50.6/32',
                            'method' => 'trust'
                          },
                          {
                            'comment' => '# Open localhost comms with database',
                            'type' => 'host', 
                            'db' => 'all',
			    'user' => 'all', 
                            'addr' => '127.0.0.1/32',
                            'method' => 'trust'
                          },
                          {
                            'comment' => '# Open IPv6 localhost comms with database',
                            'type' => 'host', 
                            'db' => 'all',
			    'user' => 'all', 
                            'addr' => '::1/128',
                            'method' => 'md5'
                          }
                        ]
                    }
                  }
      chef.run_list = [
        'role[barbican-db]'
      ]
    end
  end

  config.vm.define :barbican_api do |barbican_api|
    barbican_api.vm.hostname = "barbican-api-test"

    # Forward guest port 9311 to host port 9311. If changed, run 'vagrant reload'.
    barbican_api.vm.network :private_network, ip: "#{ip_api}", :netmask => "255.255.0.0"
    barbican_api.vm.network :forwarded_port, guest: 9311, host: 9311
    barbican_api.vm.network :forwarded_port, guest: 9312, host: 9312
    barbican_api.vm.network :forwarded_port, guest: 22, host: 2204, auto_correct: true
    barbican_api.vm.network :forwarded_port, guest: 80, host: 8004

    # Provision the node.
    barbican_api.vm.provision :chef_solo do |chef|
      chef.roles_path = "roles"
      chef.data_bags_path = "data_bags"
      chef.arguments = '-l debug'
      chef.run_list = [
        "role[barbican-api]",
      ]
      chef.json = {
          "solo_ips" => {
              "db" => "#{ip_db}",
              "queue_ips" => nodes_queue
          }
      }
    end
  end

  config.vm.define :barbican_worker do |barbican_worker|
    barbican_worker.vm.hostname = "barbican-worker-test"

    barbican_worker.vm.network :private_network, ip: "#{ip_worker}", :netmask => "255.255.0.0"
    barbican_worker.vm.network :forwarded_port, guest: 22, host: 2206, auto_correct: true
    barbican_worker.vm.network :forwarded_port, guest: 80, host: 8006

    # Forward guest port 9311 to host port 9311. If changed, run 'vagrant reload'.
    # barbican_worker.vm.network :forwarded_port, guest: 9311, host: 9311

    # Provision the node.
    barbican_worker.vm.provision :chef_solo do |chef|
      chef.roles_path = "roles"
      chef.data_bags_path = 'data_bags'
      chef.arguments = '-l debug'
      chef.run_list = [
        "role[barbican-worker]",
      ]
      chef.json = {
          "solo_ips" => {
              "db" => "#{ip_db}",
              "queue_ips" => nodes_queue
          }
      }
    end
  end

  #TODO(jwood) Make this public:
  if false
  config.vm.define :barbican_repose do |barbican_repose|
    barbican_repose.vm.hostname = "barbican-repose-test"

    barbican_repose.vm.network :private_network, ip: "#{ip_repose}", :netmask => "255.255.0.0"
    barbican_repose.vm.network :forwarded_port, guest: 8080, host: 8080

    # Provision the node.
    barbican_repose.vm.provision :chef_solo do |chef|
      chef.roles_path = "roles"
      chef.data_bags_path = "data_bags"
      chef.arguments = '-l debug'
      chef.run_list = [
        "role[barbican-repose]"
      ]
      chef.json = {
          "solo_api_host" => "#{ip_api}"
      }
    end
  end
  end

  config.berkshelf.enabled = true
  config.omnibus.chef_version = :latest

end
