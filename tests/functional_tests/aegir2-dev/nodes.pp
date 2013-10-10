node "aegir2" {

  class { 'drush::git::drush' :
    //$git_branch = '5.x',
    $git_tag    = '5.10',
  }

  class { 'aegir::dev' :
    $hostmaster_ref = '6.x-2.x',
    $provision_ref  = '6.x-2.x',
    require => Class['drush'],
  }

}
