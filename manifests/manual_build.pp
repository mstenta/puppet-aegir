class aegir::manual_build {

  # TODO: It might be interesting to use Facter to determine the FQDN
  # to set $aegir_host, and then potentially allow overrides in 
  # hostmaster-install

  # Set some defaults, or pass along those specified in the calling manifest
  # TODO: This is ugly, figure out a better way to set defaults
  if ! $http_service_type   { $http_service_type = 'apache' } else { $http_service_type = $http_service_type}
  if ! $drush_make_version { $drush_make_version = '6.x-2.3' } else { $drush_make_version = $drush_make_version }
  if ! $aegir_db_host           { $aegir_db_host = 'localhost' } else { $aegir_db_host = $aegir_db_host }
  if ! $aegir_db_user           { $aegir_db_user = 'root' } else { $aegir_db_user = $aegir_db_user }
  if ! $aegir_db_password   { $aegir_db_password = 'password' } else { $aegir_db_password = $aegir_db_password }
  if ! $aegir_email               { $aegir_email = "webmaster@localhost"} else { $aegir_email = $aegir_email }
  if ! $client_name               { $client_name = 'admin' } else { $client_name = $client_name }
  if ! $aegir_root                 { $aegir_root = '/var/aegir' } else { $aegir_root = $aegir_root }
  if ! $aegir_makefile         { $aegir_makefile = "${aegir_root}/.drush/provision/aegir.make" } else { $aegir_makefile = $aegir_makefile }
  if ! $web_group                   { $web_group = 'www-data' } else { $web_group = $web_group }
  if ! $script_user               { $script_user = 'aegir' } else { $script_user = $script_user }
  if ! $aegir_version           { $aegir_version = '6.x-1.6' } else { $aegir_version = $aegir_version }

  include aegir::manual_build::frontend

}

class aegir::manual_build::backend {
  include drush

  # Ref.: http://community.aegirproject.org/installing/manual#Create_the_Aegir_user
  group {"${aegir::manual_build::script_user}":
    ensure => present,
    system => true,
  }

  user {"${aegir::manual_build::script_user}":
    system  => 'true',
    gid     => $aegir::manual_build::script_user,
    home    => $aegir::manual_build::aegir_root,
    groups  => $aegir::manual_build::web_group,
    ensure  => present,
    require => [ Package['apache2'],
                 Group["${aegir::manual_build::script_user}"],
               ],
  }

  file { [ "${aegir::manual_build::aegir_root}", "${aegir::manual_build::aegir_root}/.drush" ]:
    owner => $aegir::manual_build::script_user,
    group => $aegir::manual_build::script_user,
    ensure  => directory,
    require => User["${aegir::manual_build::script_user}"],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_provision
  exec { 'Install provision':
    command     => "drush dl --destination=${aegir::manual_build::aegir_root}/.drush provision-${aegir::manual_build::aegir_version}",
    creates     => "${aegir::manual_build::aegir_root}/.drush/provision",
    user        => $aegir::manual_build::script_user,
    group       => $aegir::manual_build::script_user,
    logoutput   => 'on_failure',
    environment => "HOME=${aegir::manual_build::aegir_root}",
    cwd         => $aegir::manual_build::aegir_root,
    require     => File["${aegir::manual_build::aegir_root}/.drush"],
  }

}

class aegir::manual_build::frontend {
  include aegir::manual_build::backend

  # Ref.: http://community.aegirproject.org/installing/manual#Install_system_requirements
  package { ['apache2', 'php5', 'php5-cli', 'php5-gd', 'php5-mysql', 'postfix', 'sudo', 'rsync', 'git-core', 'unzip']:
    ensure => present,
    require => Exec['update_apt'],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Apache_configuration
  # TODO: only run this once, if necessary
  exec {'a2enmod rewrite':
    require => Package['apache2'],
    unless => 'apache2ctl -M | grep rewrite',
  }
  file {"/etc/apache2/conf.d/aegir.conf":
    ensure  => link,
    target  => "${aegir::manual_build::aegir_root}/config/apache.conf",
    require => Package['apache2'],
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#PHP_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Sudo_configuration
  file {"/etc/sudoers.d/aegir.sudo":
    ensure  => present,
    content => "Defaults:${aegir::manual_build::script_user}  !requiretty\n
                ${aegir::manual_build::script_user} ALL=NOPASSWD: /usr/sbin/apache2ctl",
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#DNS_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Database_configuration
  # TODO: this passes the db password on the command-line, and so is probably
  # insecure. Figure out another way to do it.
  # TODO: also, only run it once, if necessary
  package {'mysql-server': }
  exec {'Change MySQL root password':
    command => "mysqladmin --user=${aegir::manual_build::aegir_db_user} --host=${aegir::manual_build::aegir_db_host} password ${aegir::manual_build::aegir_db_password}",
    require => Package['mysql-server'],
    onlyif => "mysql -u${aegir::manual_build::aegir_db_user}",
  }

  # Note: Skipping the below (for now)
  # comment out 'bind-address = 127.0.0.1' from /etc/mysql/my.cnf 
  # exec /etc/init.d/mysql restart

  # Ref.: http://community.aegirproject.org/installing/manual#Running_hostmaster-install
  # Note: The chgrp to www-data towards the end of hostmaster-install fails,
  # and requires the file hacks and apache restart further down. This is likely
  # due to a bug in how puppet handles exec environments. See: http://projects.puppetlabs.com/issues/5224
  exec {'hostmaster-install':
    command     => "drush hostmaster-install ${aegir_site} --http_service_type=${aegir::manual_build::http_service_type} --drush_make_version=${aegir::manual_build::drush_make_version} --aegir_db_host=${aegir::manual_build::aegir_db_host} --aegir_db_user=${aegir::manual_build::aegir_db_user} --aegir_db_pass=${aegir::manual_build::aegir_db_password} --client_email=${aegir::manual_build::aegir_email} --client_name=${aegir::manual_build::client_name} --makefile=${aegir::manual_build::aegir_makefile} --script_user=${aegir::manual_build::script_user} --web_group=${aegir::manual_build::web_group} --version=${aegir::manual_build::aegir_version} --aegir_root=${aegir::manual_build::aegir_root} -y > /var/aegir/install.log 2>&1",
    creates     => "${aegir::manual_build::aegir_root}/hostmaster-${aegir::manual_build::aegir_version}/sites/${aegir::manual_build::aegir_site}",
    user        => $aegir::manual_build::script_user,
    group       => $aegir::manual_build::script_user,
    logoutput   => 'on_failure',
    environment => ["HOME=${aegir::manual_build::aegir_root}"],
    cwd         => $aegir::manual_build::aegir_root,
    require     => [ Class['aegir::manual_build::backend'],
                     Package['php5', 'php5-cli', 'php5-gd', 'php5-mysql', 'postfix', 'sudo', 'rsync', 'git-core', 'unzip'],
                     User["${aegir::manual_build::script_user}"],
                     File['/etc/apache2/conf.d/aegir.conf', '/etc/sudoers.d/aegir.sudo'],
                     Exec['a2enmod rewrite', 'Change MySQL root password'],
                   ],
  }

  exec {'one-time login':
    command => 'drush @hostmaster uli',
    user => $aegir::manual_build::script_user,
    environment => ["HOME=${aegir::manual_build::aegir_root}"],
    logoutput => true,
    loglevel  => 'alert',
    subscribe   => Exec['apache2ctl graceful'],
    refreshonly => true,
  }

  # TODO: fix hostmaster-install so that none of what follows is necessary
  file { "${aegir::manual_build::aegir_root}/hostmaster-${aegir::manual_build::aegir_version}/sites/${aegir::manual_build::aegir_site}/settings.php":
    owner   => $aegir::manual_build::script_user,
    group   => $aegir::manual_build::web_group,
    mode    => '0644',
    require => Exec['hostmaster-install'],
  }
  file { ["${aegir::manual_build::aegir_root}/hostmaster-${aegir::manual_build::aegir_version}/sites/${aegir::manual_build::aegir_site}/files",
          "${aegir::manual_build::aegir_root}/hostmaster-${aegir::manual_build::aegir_version}/sites/${aegir::manual_build::aegir_site}/private",
         ]:
    owner   => $aegir::manual_build::script_user,
    group   => $aegir::manual_build::web_group,
    mode    => '2770',
    recurse => true,
    require => Exec['hostmaster-install'],
  }
  exec { 'apache2ctl graceful':
    require     => File["${aegir::manual_build::aegir_root}/hostmaster-${aegir::manual_build::aegir_version}/sites/${aegir::manual_build::aegir_site}/files",
                        "${aegir::manual_build::aegir_root}/hostmaster-${aegir::manual_build::aegir_version}/sites/${aegir::manual_build::aegir_site}/private"],
    subscribe   => Exec['hostmaster-install'], 
    refreshonly => true,
  }

}
