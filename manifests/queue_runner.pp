class aegir::queue_runner {

# Set some defaults
  if ! $aegir_user       { $aegir_user = 'aegir' }
  if ! $aegir_root       { $aegir_root = '/var/aegir' }
  if ! ($aegir_version or $aegir_dev_build) { $aegir_version = '6.x-1.6' }
  elsif $aegir_dev_build { $aegir_version = '6.x-1.x' }
  if ! $aegir_site { $aegir_site = $fqdn }

  Exec { path => '/usr/bin:/bin:/usr/sbin', user => $aegir_user, group => $aegir_user, }

  if ($aegir_manual_build or $aegir_dev_build) { $aegir_installed = Exec['Hostmaster install'] }
  else { $aegir_installed = Package['aegir'] }


  drush::dl { 'hosting_queue_runner':
    site_path  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_site}",
    log        => "${aegir_root}/drush.log",
    require    => $aegir_installed,
    notify     => Drush::En['hosting_queue_runner'],
  }

  drush::en { 'hosting_queue_runner':
    site_path  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_site}",
    log        => "${aegir_root}/drush.log",
    require    => Drush::Dl['hosting_queue_runner'],
  }

  file {'hosting-queue-runner init script':
    source  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_site}/modules/hosting_queue_runner/init.d.example",
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
