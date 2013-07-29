class aegir::extras (
  $tasks_extra_version      = '6.x-2.0-alpha2',
  $registry_rebuild_version = '7.x-1.9',
  $aegir_version            = $aegir::defaults::api2_vers
  ) inherits aegir::defaults {

  drush::dl { 'registry_rebuild':
    version => $registry_rebuild_version,
  }

  drush::dl { 'provision_tasks_extra':
    version => $tasks_extra_version,
  }

  drush::dl { 'hosting_tasks_extra':
    version   => $tasks_extra_version,
    site_path => "${aegir::defaults::aegir_root}/hostmaster-${aegir_version}/sites/${aegir::defaults::frontend_url}",
  }

  drush::en { 'hosting_tasks_extra': }

}
