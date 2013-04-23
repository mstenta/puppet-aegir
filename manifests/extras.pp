class aegir::extras inherits aegir::defaults {

  exec {'clone registry_rebuild':
    command => "git clone --branch 7.x-1.x http://git.drupal.org/project/registry_rebuild.git",
    cwd     => "/usr/share/drush/commands/",
    user    => 'root',
    group   => 'root',
    creates => "/usr/share/drush/commands/registry_rebuild",
    require => $aegir_installed,
  }

  exec {'clone provision_tasks_extra':
    command => "git clone --branch 6.x-2.x http://git.drupal.org/project/provision_tasks_extra.git",
    cwd     => "/usr/share/drush/commands/",
    user    => 'root',
    group   => 'root',
    creates => "/usr/share/drush/commands/provision_tasks_extra",
    require => $aegir_installed,
  }

  exec {'clone hosting_tasks_extra':
    command => "git clone --branch 6.x-2.x http://git.drupal.org/project/hosting_tasks_extra.git",
    cwd     => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}/modules",
    creates => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}/modules/hosting_tasks_extra",
    require => $aegir_installed,
    notify     => Drush::En['hosting_tasks_extra'],
  }

  drush::en { 'hosting_tasks_extra':
    site_path  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}",
    log        => "${aegir_root}/drush.log",
    require    => Exec['clone hosting_tasks_extra'],
  }

}
