Puppet::Type.type(:galera_cluster).provide(:mysql) do
  desc "Mariadb support"
  
  defaultfor :kernel => 'Linux'
  
  optional_commands :mysql       => 'mysql'
  optional_commands :mysqladmin  => 'mysqladmin'
  optional_commands :service     => 'service'
  optional_commands :mysqld_safe => 'mysqld_safe'
  
  def self.defaults_file
    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
      "--defaults-file=#{Facter.value(:root_home)}/.my.cnf"
    else
      nil
    end
  end
  def defaults_file
    self.class.defaults_file
  end

  # routines to add:
  #   is mysql even installed?
  #   is mysql process started?
  #   is mysql listening at all on remote node?
  #   check the cluster status on a remote node
  #   start the mysql service with the given address
  #   restart the mysql service cos the cluster is complete
  
  
  
    
  def create
    # this routine creates the cluster - if this runs, exists? has exited false
    # first we check all the nodes to ensure mysql is listening, and if the
    # wsrep_cluster_status is primary.  If one is, we'll join it.
    
    # array cluster_servers is the list of hosts to check
    first_node = true
    gcomm_address = "gcomm://"
    @resource[:cluster_servers].each { | node | 
      if @resource[:hostname] != node # not this host, so do the check
        puts "checking host #{node} for Primary"
        #TODO - refactor this to simplify, it's ugly like this
        begin
          cluster_check_result = mysql([defaults_file, "-h", node, '-NBe', "show status like 'wsrep_cluster_status'"].compact)
          puts "Result of check on #{node} was #{cluster_check_result}"
        rescue => e
          debug(e.message)
          cluster_check_result = "someerror"
        end
        if cluster_check_result.match(/Primary/)
          first_node = false
          gcomm_address = "gcomm://#{node}"
          puts "Node #{node} matched Primary, first_node is #{first_node}, address is now #{gcomm_address}"
          # TODO what happens when mysql isn't listening on node?
          # that node is a primary, we can connect to it
          # we should end the loop here, but it probably doesn't hurt if we don't
          #break
        else
          puts "host #{node} is not a primary"
        end
      end
    }
    # after that loop, we'll have a boolean first_node that tells if this is the first node.
    if first_node == true
      puts "This is the first node of the cluster, so we will create the cluster now, address: #{gcomm_address}"
      # this is the first node, and it's not yet a cluster
    else
      puts "first node is #{first_node}, address: #{gcomm_address}"
    end

    # stop the service
    mysqladmin([defaults_file, "shutdown"].compact)
    service([@resource[:servicename], "stop"].compact)
    # start it special with the address as set above
    # TODO if this is the first node, do another check after some random sleep time, just in case...
    mysql_startup = fork do
      exec "/usr/bin/mysqld_safe --wsrep_cluster_address=#{gcomm_address}"
    end
    Process.detach(mysql_startup)
  end
  
  def destroy
    # TODO some routine to destroy the cluster?
  end
  
  def exists?
    begin
      mysql([defaults_file, '-NBe', "show status like 'wsrep_cluster_status'"].compact).match(/Primary/)
      # if this is true, then the cluster is alive and so we don't need to do anything at all
      # TODO what happens when mysql isn't listening on localhost?
      # TODO if ps -ef |grep '/bin/bash /usr/bin/mysqld_safe --wsrep_cluster_address=gcomm://' then restart if cluster members >2
    rescue => e
      debug(e.message)
      return nil
    end
  end
end
