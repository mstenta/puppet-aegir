node "aegir3-dev.test" {

  class { 'drush::git::drush' :
    git_branch => '6.x',
    #git_tag    => '6.2.0',
  }

  class { 'aegir::dev' :
    hostmaster_ref => '7.x-3.x',
    provision_ref  => '7.x-3.x',
    # This shouldn't be necessary. See: https://drupal.org/node/2114025.
    #platform_path  => '/var/aegir/hostmaster-6.x-2.x',
    require        => Class['drush::git::drush'],
  }

}
