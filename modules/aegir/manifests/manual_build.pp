class aegir::manual_build::frontend {

  # TODO: It might be interesting to use Facter to determine the FQDN
  # to set $aegir_host, and then potentially allow overrides in 
  # hostmaster-install

  # Set defaults
  if ! $http_service_type   { $http_service_type = 'apache' }
  if ! $drush_make_version { $drush_make_version = '6.x-2.3' }
  if ! $aegir_db_host           { $aegir_db_host = 'localhost' }
  if ! $aegir_db_user           { $aegir_db_user = 'root' }
  if ! $aegir_db_password   { $aegir_db_password = 'password' }
  if ! $aegir_email               { $aegir_email = "webmaster@localhost"}
  if ! $client_name               { $client_name = 'admin' }
  if ! $aegir_makefile         { $aegir_makefile = '/usr/share/drush/commands/provision/aegir.make' }
  if ! $script_user               { $script_user = 'aegir' }
  if ! $web_group                   { $web_group = 'www-data' }
  if ! $aegir_version           { $aegir_version = '6.x-1.6' }
  if ! $aegir_root                 { $aegir_root = '/var/aegir' }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_system_requirements
  package { ['apache2', 'php5', 'php5-cli', 'php5-gd', 'php5-mysql', 'postfix', 'sudo', 'rsync', 'git-core', 'unzip']:
    ensure => present,
    require => Exec['update_apt'],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Create_the_Aegir_user
  user {"${script_user}":
    system  => 'true',
    gid     => $script_user,
    home    => $aegir_root,
    groups  => $web_group,
    ensure  => present,
    require => Package['apache2'],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Apache_configuration
  # TODO: only run this once, if necessary
  exec {'a2enmod rewrite':
    require => Package['apache2'],
    #onlyif =>
  }
  file {"/etc/apache2/conf.d/aegir.conf":
    ensure  => link,
    target  => "${aegir_root}/config/apache.conf",
    require => Package['apache2'],
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#PHP_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Sudo_configuration
  file {"/etc/sudoers.d/aegir.sudo":
    ensure  => present,
    content => "Defaults:${script_user}  !requiretty\n
                ${script_user} ALL=NOPASSWD: /usr/sbin/apache2ctl",
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#DNS_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Database_configuration
  # TODO: this passes the db password on the command-line, and so is probably
  # insecure. Figure out another way to do it.
  # TODO: also, only run it once, if necessary
  package {'mysql-server': }
  exec {'Change MySQL root password':
    command => "mysqladmin --user=${aegir_db_user} --host=${aegir_db_host} password ${aegir_db_password}",
    require => Package['mysql-server'],
    #onlyif =>
  }

  # Note: Skipping the below (for now)
  # comment out 'bind-address = 127.0.0.1' from /etc/mysql/my.cnf 
  # exec /etc/init.d/mysql restart

  # Ref.: http://community.aegirproject.org/installing/manual#Install_provision
  include aegir::backend


  # Ref.: http://community.aegirproject.org/installing/manual#Running_hostmaster-install
  exec {'hostmaster-install':
    command     => "drush hostmaster-install ${aegir_site} --http_service_type=${http_service_type} --drush_make_version=${drush_make_version} --aegir_db_host=${aegir_db_host} --aegir_db_user=${aegir_db_user} --aegir_db_pass=${aegir_db_password} --client_email=${aegir_email} --client_name=${client_name} --makefile=${aegir_makefile} --script_user=${script_user} --web_group=${web_group} --version=${aegir_version} --aegir_root=${aegir_root} -y > /var/aegir/install.log",
    path        => "/bin/:/sbin/:/usr/bin/:/usr/sbin/",
    user        => $script_user,
    group       => $script_user,
    logoutput   => 'on_failure',
    environment => ["HOME=${aegir_root}",], # 'SUDO_UID=107','SUDO_GID=111', 'SUDO_USER=aegir', 'USER=aegir', 'USERNAME=aegir'],
    cwd         => $aegir_root,
    require     => [ Class['aegir::backend'],
                     Package['php5', 'php5-cli', 'php5-gd', 'php5-mysql', 'postfix', 'sudo', 'rsync', 'git-core', 'unzip'],
                     User["${script_user}"],
                     File['/etc/apache2/conf.d/aegir.conf', '/etc/sudoers.d/aegir.sudo'],
                     Exec['a2enmod rewrite', 'Change MySQL root password'],
                   ],
  }

  # TODO: fix hostmaster-install so this isn't necessary
  file { "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_site}/settings.php":
    owner   => $script_user,
    group   => $web_group,
    mode    => '0644',
    require => Exec['hostmaster-install'],
  }
  file { ["${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_site}/files",
          "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_site}/private",
         ]:
    owner   => $script_user,
    group   => $web_group,
    mode    => '2770',
    recurse => true,
    require => Exec['hostmaster-install'],
  }

}
