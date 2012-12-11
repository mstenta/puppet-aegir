class aegir::queued inherits aegir::defaults {

  drush::en { 'hosting_queued':
    site_path  => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}",
    log        => "${aegir_root}/drush.log",
    require    => $aegir_installed,
  }

  file {'hosting-queued init script':
    # ref.: http://drupalcode.org/project/hosting_queue_runner.git/blob_plain/refs/heads/6.x-1.x:/init.d.example
    source  => "puppet:///modules/aegir/init.d.example-new",
    path    => "/etc/init.d/hosting-queued",
    mode    => '755',
    owner   => 'root',
    group   => 'root',
    ensure  => present,
  }

  service {'hosting-queued':
    ensure    => running,
    enable    => true,
    subscribe => File['hosting-queued init script'],
    require   => Drush::En['hosting_queued'],
  }

}
