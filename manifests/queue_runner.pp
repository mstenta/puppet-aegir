class aegir::queue_runner {

  include aegir::defaults

# Set some defaults
  if ! $aegir_user       { $aegir_user = 'aegir' }
  if ! $aegir_root       { $aegir_root = '/var/aegir' }
  if ! ($aegir_version or $aegir_dev_build) { $aegir_version = '6.x-1.6' }
  elsif $aegir_dev_build { $aegir_version = '6.x-1.x' }
  if ! $aegir_hostmaster_url { $aegir_hostmaster_url = $fqdn }

  drush::dl { 'hosting_queue_runner':
    site_path  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}",
    log        => "${aegir_root}/drush.log",
    require    => Class['aegir'],
    notify     => Drush::En['hosting_queue_runner'],
  }

  drush::en { 'hosting_queue_runner':
    site_path  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}",
    log        => "${aegir_root}/drush.log",
    require    => Drush::Dl['hosting_queue_runner'],
  }

  file {'hosting-queue-runner init script':
    source  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}/modules/hosting_queue_runner/init.d.example",
    path    => "/etc/init.d/hosting-queue-runner",
    mode    => '755',
    ensure  => present,
    require => Drush::Dl['hosting_queue_runner'],
  }

  service {'hosting-queue-runner':
    ensure    => running,
    enable    => true,
    subscribe => File['hosting-queue-runner init script'],
    require   => Drush::En['hosting_queue_runner'],
    # TODO: remove this line once http://drupal.org/node/1404226 is fixed
    status    => 'ps aux | grep hosting-queue-runner',
  }

}
