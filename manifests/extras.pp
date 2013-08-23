class aegir::extras inherits aegir::defaults {

  drush::dl { 'registry_rebuild':
    type => 'extension',
  }

  drush::dl { 'provision_tasks_extra':
    type => 'extension',
  }

  drush::dl { 'hosting_tasks_extra': }

  drush::en { 'hosting_tasks_extra': }

}
