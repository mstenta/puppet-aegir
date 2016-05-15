node "aegir3-dev-drush8.test" {

  class { 'drush::git::drush' :
    git_branch => '8.x',
  }

  class { 'aegir::dev' :
    hostmaster_ref => '7.x-3.x',
    provision_ref  => '7.x-3.x',
    platform_path  => '/var/aegir/hostmaster-7.x-3.x',
    require        => Class['drush::git::drush'],
    start_queued_service => false,
  }

  drush::run { 'Clear Drush caches for Aegir':
    command    => 'cache-clear',
    site_alias => '@hostmaster',
    arguments  => 'all',
    drush_user => 'aegir',
    drush_home => '/var/aegir',
    require    => Class['aegir::dev'],
  }
}
