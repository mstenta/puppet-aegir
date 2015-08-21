node "aegir3-unstable" {

  class { 'drush' :
    api  => 6,
  }

  class { 'aegir' :
    api     => 3,
    dist    => 'unstable',
    require => Class['drush'],
  }

}
