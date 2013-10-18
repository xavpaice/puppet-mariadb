Facter.add("wsrep_cluster_status") do
  setcode do
    queryitem  = "'wsrep_cluster_status'"
    if File.exist?('/usr/bin/mysql')
      %x(mysql --defaults-file=#{Facter.value(:root_home)}/.my.cnf -NBe "show status like #{queryitem};").split[1]
    else
      nil
    end
  end
end
