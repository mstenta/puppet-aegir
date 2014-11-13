node "aegir3-drush-master-dev.test" {

  class { 'drush::git::drush' :
    git_branch => 'master',
    #git_tag    => '6.2.0',
  }

  class { 'aegir::dev' :
    hostmaster_ref => '7.x-3.x',
    provision_ref  => '7.x-3.x',
    platform_path  => '/var/aegir/hostmaster-7.x-3.x',
    require        => Class['drush::git::drush'],
  }

}
