node "aegir2" {

  class { 'drush' :
    api  => 5,
  }

  class { 'aegir' :
    api     => 2,
    dist    => 'unstable',
    require => Class['drush'],
  }

}
