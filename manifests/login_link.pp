class aegir::login_link {

  if ! $script_user { $script_user = 'aegir' }
  if ! $aegir_root { $aegir_root = '/var/aegir' }

  exec {'login link':
    command => 'drush @hostmaster uli',
    user => $script_user,
    environment => ["HOME=${aegir_root}"],
    logoutput => true,
    loglevel => 'alert',
    refreshonly => true,
  }

}
