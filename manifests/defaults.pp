class aegir::defaults {

  $aegir_root   = '/var/aegir'
  $aegir_user   = 'aegir'
  $frontend_url = false
  $db_host      = false
  $db_user      = false
  $db_password  = false
  $admin_email  = false
  $admin_name   = false
  $makefile     = false
  $api          = ''
  $dist         = 'stable'
  $ensure       = 'present'
  $db_server    = 'mysql'
  $secure_mysql = false
  $web_server   = 'apache2'
  $web_group    = 'www-data'

  if defined(Class['aegir::dev']) {
    $aegir_installed = Class['aegir::dev']
  }
  else {
    $aegir_installed = Class['aegir']
  }

  Drush::Run {
    site_alias => '@hostmaster',
    drush_user => $aegir_user,
    drush_home => $aegir_root,
    log        => "${aegir_root}/drush.log"
  }
  Drush::Dl {
    site_alias => '@hostmaster',
    drush_user => $aegir_user,
    drush_home => $aegir_root,
    log        => "${aegir_root}/drush.log"
  }
  Drush::En {
    site_alias => '@hostmaster',
    drush_user => $aegir_user,
    drush_home => $aegir_root,
    log        => "${aegir_root}/drush.log"
  }

}
