class aegir::login_link {

  if ! $aegir_user { $aegir_user = 'aegir' }
  if ! $aegir_root { $aegir_root = '/var/aegir' }

  exec {'login link':
    command => 'drush @hostmaster uli',
    user => $aegir_user,
    environment => ["HOME=${aegir_root}"],
    logoutput => true,
    loglevel => 'alert',
    refreshonly => true,
  }

}
