node "aegir3-dev-drush7.test" {

  class { 'drush::git::drush' :
    git_branch => '7.x',
  }

  class { 'aegir::dev' :
    hostmaster_ref => '7.x-3.x',
    provision_ref  => '7.x-3.x',
    platform_path  => '/var/aegir/hostmaster-7.x-3.x',
    require        => Class['drush::git::drush'],
  }

}
