using './main.bicep' /*Provide a path to a bicep template*/

  param VnetName = 'default'
  param aksClusterName = 'akscluster'
  param aksClusterNodeCount = 2
  param aksClusterNodeSize = 'Standard_D2_v2'
  param aksClusterKubernetesVersion = '1.30'
  param aksdnsPrefix = 'danagcaksdns'
  param linuxadmin = 'danadmin'
  param sshkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDSKkXzsOth/cxH5mCb/xbJY00viNN3X2GOQ7bx6lgqyLZsYaIXWfUdj37E9cN5ZFP/UOev6wuKqRscqixHh4NJ7HMRTmbx53Pu13p+iXHoSN5rULK5+y5LREUnfiqSgGBY3UhYVtBYtMKRjPFIL+8mVxze5cpH64Vt4HwL13EXd7fQtEBiaNtB6lc43mIGV/UX69qPHzPKr/GSct2S0yLQMG7sv3NizKsDajxG7E94Qn77K/euFzDT/piEN3U+4qvshMe92m07puRfIooF4xXQpA0ScDIQruKGjmomkpNwehyZbGCjUhUXWmt6sNy/04/hSp1eQEsqzMA1et3JzcvazMogtAvjRpDwAhMETesFx7GL7fN21P1fyTDIiL3W43qX9VibndrE7/Ugkyq/M2QhNvYJgSojuBElDU2uJtRhqfrFrpcy8+mBB9TD4PmKvonVvunfkQX5vr9tcctWkfKsyGSvLtUQ4bQXH3wCJJjJ579hDWS1PBuNJWEZ51GnmPZWL4QOaWZyPi+uThYhiWBCAQ7j8Iq1kTEJyHpjHGlGfXamu0EUR8Q0cIWM8TUWyILBKbdsKQ/MtP6FVJsso4BCWCrCCQEGQAnSZ9fhBw87v8zkBzW0iRblgGP+fhDFQLdqMtBMLHMwbZbXA/GbHx35K951mA1xQ4R39zFMQ+9ZoQ== danwheeler@LAPTOP-3DALUHP4'
  param akspodcidr = '192.168.0.0/20'
  param aksserviceCidr = '192.168.16.0/20'
  param aksinternalDNSIP = '192.168.16.10'
  param AGCname = 'agc'
  param AssociationName = 'agcassociation'
  param subnet_Names = [
    'aks_nodes'
    'AGCSubnet'
  ]
  param dnsServers = []
  param virtualNetwork_AddressPrefix = '10.0.0.0/8'
