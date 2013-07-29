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
    default: { /* mysql will be installed as a dependency of the aegir packages. */ }
  }

  case $web_server {
    'nginx': { /* To do */ }
    default: { /* apache2 will be installed as a dependency of the aegir packages. */ }
  }

  if $frontend_url { exec {"echo debconf aegir/site string ${frontend_url} | debconf-set-selections":       before => Package['aegir'], } }
  if $db_host      { exec {"echo debconf aegir/db_host string ${db_host} | debconf-set-selections":         before => Package['aegir'], } }
  if $db_user      { exec {"echo debconf aegir/db_user string ${db_user} | debconf-set-selections":         before => Package['aegir'], } }
  if $db_password  { exec {"echo debconf aegir/db_password string ${db_password} | debconf-set-selections": before => Package['aegir'], } }
  if $admin_email  { exec {"echo debconf aegir/email string ${admin_email} | debconf-set-selections":       before => Package['aegir'], } }
  if $makefile     { exec {"echo debconf aegir/makefile string ${makefile} | debconf-set-selections":       before => Package['aegir'], } }

  package { "aegir${real_api}":
    ensure       => $ensure,
    responsefile => 'files/aegir.preseed',
    require      => Class['aegir::apt'],
  }

}
