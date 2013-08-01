class aegir (
  $frontend_url = $aegir::defaults::frontend_url,
  $db_host      = $aegir::defaults::db_host,
  $db_user      = $aegir::defaults::db_user,
  $db_password  = $aegir::defaults::db_password,
  $admin_email  = $aegir::defaults::admin_email,
  $makefile     = $aegir::defaults::makefile,
  $api          = $aegir::defaults::api,
  $apt          = $aegir::defaults::apt,
  $dist         = $aegir::defaults::dist,
  $db_server    = $aegir::defaults::db_server,
  $web_server   = $aegir::defaults::web_server,
  $ensure       = $aegir::defaults::ensure
  ) inherits aegir::defaults {


  case $api {
    2: {
      $real_api = 2
      package { 'aegir':
        ensure => absent;
      }
      include drush
    }
    1, '': {
      $real_api = ''
      class{ 'drush':
        api => 4,
      }
    }
    default: {
      warning("'${api}' is not a valid Aegir API version. Values can be '1' or '2'. Defaulting to '1'.")
      $real_api = ''
    }
  }

  if $apt {
    class { 'aegir::apt' :
      dist => $dist,
    }
  }

  case $db_server {
    'mariadb': { /* To do */ }
    'mysql', default: { /* mysql will be installed as a dependency of the aegir packages. */ }
  }

  case $web_server {
    'nginx': { /* To do */ }
    'apache2', default: { /* apache2 will be installed as a dependency of the aegir packages. */ }
  }

  Aegir::Apt::Debconf { before => Package['aegir'] }
  if $frontend_url { aegir::apt::debconf { "aegir/site string ${frontend_url}": } }
  if $db_host      { aegir::apt::debconf { "aegir/db_host string ${db_host}": } }
  if $db_user      { aegir::apt::debconf { "aegir/db_user string ${db_user}": } }
  if $db_password  { aegir::apt::debconf { "aegir/db_password string ${db_password}": } }
  if $admin_email  { aegir::apt::debconf { "aegir/email string ${admin_email}": } }
  if $makefile     { aegir::apt::debconf { "aegir/makefile string ${makefile}": } }

  package { "aegir${real_api}":
    ensure       => $ensure,
    responsefile => 'files/aegir.preseed',
    require      => Class['aegir::apt'],
  }

}
