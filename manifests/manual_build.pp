class aegir::manual_build {

  include aegir::manual_build::frontend
  include aegir::login_link

}

class aegir::manual_build::backend {
  include drush

  # Set some defaults
  if ! $aegir_user                             { $aegir_user = 'aegir' }
  if ! $aegir_root                             { $aegir_root = '/var/aegir' }
  if ! $aegir_web_group                   { $aegir_web_group = 'www-data' }
  if $aegir_dev_build                    { $aegir_version = '6.x-1.x' }
  elsif ! $aegir_version                 { $aegir_version = '6.x-1.6' }

  # Ref.: http://community.aegirproject.org/installing/manual#Create_the_Aegir_user
  group {$aegir_user:
    ensure => present,
    system => true,
  }

  user {$aegir_user:
    system  => 'true',
    gid     => $aegir_user,
    home    => $aegir_root,
    groups  => $aegir_web_group,
    ensure  => present,
    require => [ Package['apache2'],
                 Group["${aegir_user}"],
               ],
  }

  file { [ $aegir_root, "${aegir_root}/.drush" ]:
    owner   => $aegir_user,
    group   => $aegir_user,
    ensure  => directory,
    require => User["${aegir_user}"],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_provision
  if ! $aegir_dev_build { 
    $command = "drush dl --destination=${aegir_root}/.drush provision-${aegir_version}" }
  else { 
    $command = "git clone --branch ${aegir_version} http://git.drupal.org/project/provision.git" }

  exec { 'Install provision':
    command     => $command,
    creates     => "${aegir_root}/.drush/provision",
    user        => $aegir_user,
    group       => $aegir_user,
    logoutput   => 'on_failure',
    environment => "HOME=${aegir_root}",
    cwd         => "${aegir_root}/.drush",
    require     => File[ "${aegir_root}", "${aegir_root}/.drush"],
  }

}

class aegir::manual_build::frontend {
  include aegir::manual_build::backend

  # Set some defaults
  if ! $aegir_user { $aegir_user = $aegir::manual_build::backend::aegir_user }
  if ! $aegir_root { $aegir_root = $aegir::manual_build::backend::aegir_root }
  if ! $aegir_web_group { $aegir_web_group = $aegir::manual_build::backend::aegir_web_group }
  if ! $aegir_version { $aegir_version = $aegir::manual_build::backend::aegir_version }
  if ! $aegir_hostmaster_url { $aegir_hostmaster_url = $fqdn }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_system_requirements
  package { ['apache2', 'php5', 'php5-cli', 'php5-gd', 'php5-mysql', 'postfix', 'sudo', 'rsync', 'git-core', 'unzip']:
    ensure  => present,
    require => Exec['update_apt'],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Apache_configuration
  exec {'a2enmod rewrite':
    require     => Package['apache2'],
    unless      => 'apache2ctl -M | grep rewrite',
    refreshonly => true,
  }
  file {"/etc/apache2/conf.d/aegir.conf":
    ensure  => link,
    target  => "${aegir_root}/config/apache.conf",
    require => Package['apache2'],
    notify  => Exec['a2enmod rewrite'],
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#PHP_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Sudo_configuration
  file {"/etc/sudoers.d/aegir.sudo":
    ensure  => present,
    content => "Defaults:${aegir_user}  !requiretty\n
                ${aegir_user} ALL=NOPASSWD: /usr/sbin/apache2ctl",
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#DNS_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Database_configuration
  package {'mysql-server': }
  # Note: Skipping the below (for now)
  # comment out 'bind-address = 127.0.0.1' from /etc/mysql/my.cnf 
  # exec /etc/init.d/mysql restart

  # Ref.: http://community.aegirproject.org/installing/manual#Running_hostmaster-install
  # Note: The chgrp to www-data towards the end of hostmaster-install fails,
  # and requires the exec hacks and apache restart further down. This is likely
  # due to a bug in how puppet handles exec environments. See: http://projects.puppetlabs.com/issues/5224

  # Build our options
  if $aegir_user {              $a = " --script_user=${aegir_user}" }
  if $aegir_root {              $b = " --aegir_root=${aegir_root}" }
  if $aegir_web_group {         $c = " --web_group=${aegir_web_group}" }
  if $aegir_version {           $d = " --aegir_version=${aegir_version}" }
  if $aegir_db_host {           $e = " --aegir_db_host=${aegir_db_host}" }
  if $aegir_db_user {           $f = " --aegir_db_user${aegir_db_user}" }
  if $aegir_db_password {       $g = " --aegir_db_pass=${aegir_db_password}" }
  if $aegir_http_service_type { $h = " --http_service_type=${aegir_http_service_type}"} 
  if $aegir_drush_make_version{ $i = " --drush_make_version=${aegir_drush_make_version}"}
  if $aegir_client_email {      $j = " --client_email=${aegir_client_email}"}
  if $aegir_client_name {       $k = " --client_name=${aegir_client_name}"}
  if $aegir_makefile {          $l = " --makefile=${aegir_makefile}"}
  if $aegir_host  {             $m = " --aegir_host=${aegir_host}"}
  if $aegir_dev_build {         $n = " --working-copy"}
  $install_options = "${a}${b}${c}${d}${e}${f}${g}${h}${i}${j}${k}${l}${m}${n}"

  exec {'hostmaster-install':
    command     => "drush hostmaster-install ${aegir_hostmaster_url} $install_options -y > /var/aegir/install.log 2>&1",
    creates     => "${aegir_root}/hostmaster-${aegir_version}",
    user        => $aegir_user,
    group       => $aegir_user,
    logoutput   => 'on_failure',
    environment => ["HOME=${aegir_root}"],
    cwd         => $aegir_root,
    require     => [ Class['aegir::manual_build::backend'],
                     Package['php5', 'php5-cli', 'php5-gd', 'php5-mysql', 'postfix', 'sudo', 'rsync', 'git-core', 'unzip', 'mysql-server'],
                     User[$aegir_user],
                     File['/etc/apache2/conf.d/aegir.conf', '/etc/sudoers.d/aegir.sudo'],
                     Exec['a2enmod rewrite'],
                   ],
    notify      => Exec[ "chgrp on ${aegir_hostmaster_url}" ],
  }

  # TODO: fix hostmaster-install so that none of what follows is necessary
  exec { "chgrp on ${aegir_hostmaster_url}":
    command     => "chgrp ${aegir_web_group} ./settings.php ./files/ ./private/",
    require     => Exec['hostmaster-install'],
    cwd         => "${aegir_root}/hostmaster-${aegir_version}/sites/${aegir_hostmaster_url}",
    refreshonly => true,
    notify      => Exec ['apache2ctl graceful'],
  }
  exec { 'apache2ctl graceful':
    refreshonly => true,
    notify      => Exec['login link'],
  }

}
