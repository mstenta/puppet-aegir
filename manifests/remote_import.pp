class aegir::remote_import inherits aegir::defaults {

/*
 # Pending http://drupal.org/node/1662822
  drush::dl { 'remote_import':
    site_path  => "${aegir_root}",
    log        => "${aegir_root}/drush.log",
    require    => $aegir_installed,
  }
*/

  exec {'clone remote_import':
    # Here we're using a sandbox that has a patch applied.
    command => "git clone --branch 1663066 http://git.drupal.org/sandbox/ergonlogic/1681684.git remote_import",
    cwd     => "/usr/share/drush/commands/provision/",
    user    => 'root',
    group   => 'root',
    creates => "/usr/share/drush/commands/provision/remote_import",
    require => $aegir_installed,
  }

/*
 # Pending http://drupal.org/node/1662820
  drush::dl { 'hosting_remote_import':
    site_path  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}",
    log        => "${aegir_root}/drush.log",
    require    => [ $aegir_installed,
                    Drush::Dl['remote_import'],
                  ],
    notify     => Drush::En['hosting_remote_import'],
  }
*/
  exec {'clone hosting_remote_import':
    command => "git clone --branch 6.x-1.x http://git.drupal.org/project/hosting_remote_import.git",
    cwd     => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}/modules",
    creates => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}/modules/hosting_remote_import",
    require => [ $aegir_installed,
                 Exec['remote_import'],
               ],
    notify     => Drush::En['hosting_remote_import'],
  }



  drush::en { 'hosting_remote_import':
    site_path  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}",
    log        => "${aegir_root}/drush.log",
    require    => Exec['clone hosting_remote_import'], #Drush::Dl['hosting_remote_import'],
  }

  # TODO: ssh key share for aegir user
  # TODO: fix http://drupal.org/node/1663066
}
