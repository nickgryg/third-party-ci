# A Jenkins slave that will execute jobs that use devstack
# to set up a full OpenStack environment for test runs.

class third_party_ci::slave (
  $bare = true,
  $certname = $::fqdn,
  $ssh_key = '',
  $python3 = false,
  $include_pypy = false,
) {
  include third_party_ci::base
  include openstack_project::tmpcleanup
  class { 'jenkins::slave':
    bare         => $bare,
    ssh_key      => $ssh_key,
    python3      => $python3,
    include_pypy => $include_pypy,
  }
  include devstack_host
}
