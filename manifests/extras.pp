class aegir::extras (
  $tasks_extra_version      = '6.x-2.0-alpha2',
  $registry_rebuild_version = '7.x-1.9',
  ) inherits aegir::defaults {

  drush::dl { 'registry_rebuild':
    version => $registry_rebuild_version,
  }

  drush::dl { 'provision_tasks_extra':
    version => $tasks_extra_version,
  }

  drush::dl { 'hosting_tasks_extra':
    version   => $tasks_extra_version,
  }

  drush::en { 'hosting_tasks_extra': }

}
