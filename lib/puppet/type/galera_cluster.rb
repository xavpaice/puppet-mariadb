Puppet::Type.newtype(:galera_cluster) do
  @doc = "Checks if a Galera cluster is up and running on the cluster members,
  and if the members are all listening but no cluster is defined, define a cluster
  if this is the first in the list of cluster members.  If it is not the first
  then just exit quietly."
  
  ensurable
  
  newparam(:name) do
    desc "The Galera cluster name, and also the name of this resource"
  end
  newparam(:cluster_servers) do
    desc "Array of hostnames in the cluster"
  end
  newparam(:hostname) do
    desc "the hostname of this node"
  end
  newparam(:servicename) do
    desc "The name of the mysql/mariadb service"
  end
end
