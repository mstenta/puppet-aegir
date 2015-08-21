class aegir::backend (
  $api      = $aegir::defaults::api,
  $dist     = $aegir::defaults::dist,
  $ensure   = $aegir::defaults::ensure
  ) inherits aegir::defaults {

  class { 'drush': }

  if $dist {
    class { 'aegir::apt' :
      dist   => $dist,
      before => Package["aegir-provision${real_api}"]
    }
  }

  $apis = ['1', '2', '3']

  case $api {
    1: {
      $real_api = ''
    }
    2: {
      $real_api = 2
      package { 'aegir-provision':
        ensure => absent;
      }
    }
    3, '', default: {
      $real_api = 3
      package { [ 'aegir2-provision', 'aegir-provision']:
        ensure => absent;
      }
      if !($api in $apis) {
        warning("'${api}' is not a valid Aegir API version. Values can be '1', '2' or '3'. Defaulting to '3'.")
      }
    }
  }

  package { "aegir-provision${real_api}" :
    ensure  => $ensure,
    require => Class['drush'],
  }
}
