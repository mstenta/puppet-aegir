node "aegir2-backports.test" {

  class { 'drush::git::drush' :
    git_branch => '5.x',
    #git_tag    => '5.10.0',
  }

  class { 'aegir::dev' :
    hostmaster_ref => '6.x-2.x-backports',
    provision_ref  => '6.x-2.x-backports',
    # This shouldn't be necessary. See: https://drupal.org/node/2114025.
    platform_path  => '/var/aegir/hostmaster-6.x-2.x',
    require        => Class['drush::git::drush'],
  }

}
