class aegir::remote_import inherits aegir::defaults {

/*
 # Pending http://drupal.org/node/1662822
  drush::dl { 'remote_import':
    site_path  => "${aegir_root}",
    log        => "${aegir_root}/drush.log",
    require    => $aegir_installed,
  }
*/

  exec {'remote_import':
    command => "git clone --recursive --branch 6.x-1.x http://git.drupal.org/project/remote_import.git",
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
  exec {'hosting_remote_import':
    command => "git clone --recursive --branch 6.x-1.x http://git.drupal.org/project/hosting_remote_import.git",
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
    require    => Exec['hosting_remote_import'], #Drush::Dl['hosting_remote_import'],
  }

  # TODO: ssh key share for aegir user
  # TODO: fix http://drupal.org/node/1663066
}
