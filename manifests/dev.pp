class aegir::dev (
  $frontend_url = $fqdn,
  $db_host      = $aegir::defaults::db_host,
  $db_user      = $aegir::defaults::db_user,
  $db_password  = $aegir::defaults::db_password,
  $admin_email  = $aegir::defaults::admin_email,
  $admin_name   = $aegir::defaults::admin_name,
  $makefile     = $aegir::defaults::makefile,
  $aegir_user   = $aegir::defaults::aegir_user,
  $aegir_root   = $aegir::defaults::aegir_root,
  $web_group    = $aegir::defaults::web_group,
  $db_server    = $aegir::defaults::db_server,
  $web_server   = $aegir::defaults::web_server,
  $update       = false,
  $platform_path      = false,
  $drush_make_version = false,
  $hostmaster_repo    = 'http://git.drupal.org/project/hostmaster.git',
  $hostmaster_ref     = '7.x-3.x',
  $provision_repo     = 'http://git.drupal.org/project/provision.git',
  $provision_ref      = '7.x-3.x'
  ) inherits aegir::defaults {

  include drush::git::drush

  # Ref.: http://community.aegirproject.org/installing/manual#Create_the_Aegir_user
  group {$aegir_user:
    ensure => present,
    system => true,
  }

  user {$aegir_user:
    ensure  => present,
    system  => true,
    gid     => $aegir_user,
    home    => $aegir_root,
    groups  => $web_group,
    require => Group[$aegir_user],
  }

  file { [ $aegir_root, "${aegir_root}/.drush" ]:
    ensure  => directory,
    owner   => $aegir_user,
    group   => $aegir_user,
    require => User[$aegir_user],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_provision
  drush::git { 'Install provision':
    git_repo   => $provision_repo,
    git_branch => $provision_ref,
    dir_name   => 'provision',
    path       => "${aegir_root}/.drush/",
    require    => File[ $aegir_root, "${aegir_root}/.drush"],
    update     => $update,
  }

  file {"${aegir_root}/.drush/provision":
    ensure  => present,
    owner   => 'aegir',
    group   => 'aegir',
    recurse => true,
    require => Drush::Git['Install provision'],
    before  => Drush::Run['hostmaster-install'],
  }

  drush::run { 'cache-clear drush':
    site_alias => '@none',
    require    => File["${aegir_root}/.drush/provision"],
    before     => Drush::Run['hostmaster-install'],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_system_requirements
  exec { 'aegir_dev_update_apt':
    command     => '/usr/bin/apt-get update && sleep 1',
  }

  package { ['php5', 'php5-cli', 'php5-gd', 'php5-mysql', 'postfix', 'sudo', 'rsync', 'git', 'unzip']:
    ensure  => present,
    require => Exec['aegir_dev_update_apt'],
    before  => Drush::Run['hostmaster-install'],
  }

  package { $web_server :
    ensure  => present,
    require => Exec['aegir_dev_update_apt'],
    before  => [
      User[$aegir_user],
      Drush::Run['hostmaster-install'],
    ],
  }

  case $web_server {
    # Ref.: http://community.aegirproject.org/installing/manual#Nginx_configuration
    'nginx': {
      $http_service_type = 'nginx'
      package { 'php5-fpm':
        ensure => present,
        require => Exec['aegir_dev_update_apt'],
        before => File['/etc/nginx/conf.d/aegir.conf'],
      }
      file { '/etc/nginx/conf.d/aegir.conf' :
        ensure  => link,
        target  => "${aegir_root}/config/nginx.conf",
        require => Package[$web_server],
        before  => Drush::Run['hostmaster-install'],
      }
    }
    # Ref.: http://community.aegirproject.org/installing/manual#Apache_configuration
    'apache2': {
      $http_service_type = 'apache'
      exec { 'Enable mod-rewrite' :
        command     => 'a2enmod rewrite',
        unless      => 'apache2ctl -M | grep rewrite',
        refreshonly => true,
        path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
        require     => Package[$web_server],
        before      => Drush::Run['hostmaster-install'],
      }
      file { '/etc/apache2/conf.d/aegir.conf':
        ensure  => link,
        target  => "${aegir_root}/config/apache.conf",
        notify  => Exec['Enable mod-rewrite'],
        require => Package[$web_server],
        before  => Drush::Run['hostmaster-install'],
      }
    }
    default: {
      err("'${web_server}' is not a supported web server. Supported web servers include 'apache2' or 'nginx'.")
    }

  }

  # Note: skipping http://community.aegirproject.org/installing/manual#PHP_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Sudo_configuration
  file {'/etc/sudoers.d/aegir':
    ensure  => present,
    content => "aegir ALL=NOPASSWD: /usr/sbin/apache2ctl\naegir ALL=NOPASSWD: /etc/init.d/nginx\n",
    mode    => '0440',
    before  => Drush::Run['hostmaster-install'],
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#DNS_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Database_configuration
  case $db_server {
    'mysql': {
      package {'mysql-server':
        ensure  => present,
        require => Exec['aegir_dev_update_apt'],
        before  => Drush::Run['hostmaster-install'],
      }
      exec { 'remove the anonymous accounts from the mysql server':
        command     => 'echo "DROP USER \'\'@\'localhost\';" | mysql && echo "DROP USER \'\'@\'`hostname`\';" | mysql',
        path        => ['/bin', '/usr/bin'],
        refreshonly => true,
        subscribe   => Package['mysql-server'],
        before      => Drush::Run['hostmaster-install'],
      }
    }
    #'mariadb': { /* To do */ }
    #'postgresql': { /* To do */ }
    default: {
      err("'${db_server}' is not a supported database server. Supported database servers include 'mysql'.")
    }
  }

  # Note: Skipping the below (for now)
  # comment out 'bind-address = 127.0.0.1' from /etc/mysql/my.cnf
  # exec /etc/init.d/mysql restart

  # Ref.: http://community.aegirproject.org/installing/manual#Running_hostmaster-install

  # Build our options
  $default_options = " --debug --working-copy --strict=0 --no-gitinfofile --aegir_version=${hostmaster_ref}"
  if $aegir_user {        $a = " --script_user=${aegir_user}" }
  if $aegir_root {        $b = " --aegir_root=${aegir_root}" }
  if $web_group {         $c = " --web_group=${web_group}" }
  if $db_host {           $d = " --aegir_db_host=${db_host}" }
  if $db_user {           $e = " --aegir_db_user${db_user}" }
  if $db_password {       $f = " --aegir_db_pass=${db_password}" }
  if $http_service_type { $g = " --http_service_type=${http_service_type}"}
  if $drush_make_version{ $h = " --drush_make_version=${drush_make_version}"}
  if $admin_email {       $i = " --client_email=${admin_email}"}
  if $admin_name {        $j = " --client_name=${admin_name}"}
  if $makefile {          $k = " --makefile=${makefile}"}
  if $frontend_url {      $l = " --aegir_host=${frontend_url}"}
  if $platform_path {     $m = " --root=${platform_path}" }
  $install_options = "$default_options${a}${b}${c}${d}${e}${f}${g}${h}${i}${j}${k}${l}${m}"

  drush::run {'hostmaster-install':
    site_alias => '@none',
    arguments  => $frontend_url,
    options    => $install_options,
    log        => '/var/aegir/install.log',
    creates    => "${aegir_root}/hostmaster-${hostmaster_ref}",
    drush_user => $aegir_user,
    drush_home => $aegir_root,
    require    => User[$aegir_user],
    timeout    => 0,
  }

  file { 'queue daemon init script':
    source  => 'puppet:///modules/aegir/init.d.example-new',
    path    => '/etc/init.d/hosting-queued',
    owner   => 'root',
    mode    => 0755,
    require => Drush::Run['hostmaster-install'],
  }
  drush::en { 'hosting_queued':
    refreshonly => true,
    subscribe   => File['queue daemon init script'],
    before      => Service['hosting-queued'],
  }
  service { 'hosting-queued':
    ensure  => running,
    subscribe => File['queue daemon init script'],
  }

  exec {'aegir-dev login':
    command     => "\
echo '*******************************************************************************'\n
echo '* Open the link below to access your new Aegir site:'\n
echo '*' `env HOME=/var/aegir drush @hostmaster uli`\n
echo '*******************************************************************************'\n
",
    loglevel    => 'alert',
    logoutput   => true,
    user        => 'aegir',
    environment => 'HOME=/var/aegir',
    path        => ['/bin', '/usr/bin'],
    require     => Drush::Run['hostmaster-install'],
  }

  if $update {
    $hostmaster_dir = "${aegir_root}/hostmaster-${hostmaster_ref}/profiles/hostmaster"
    $hosting_dir    = "${hostmaster_dir}/modules/hosting"
    $eldir_dir      = "${hostmaster_dir}/themes/eldir"
    exec { 'update hostmaster':
      command => "cd ${hostmaster_dir} && git pull -r",
    }
    exec { 'update hosting':
      command => "cd ${hosting_dir} && git pull -r",
    }
    exec { 'update eldir':
      command => "cd ${eldir_dir} && git pull -r",
    }
    drush::run {'update_db':
      site_alias => '@hostmaster',
      require    => [
        Exec['update hostmaster'],
        Exec['update hosting'],
        Exec['update eldir'],
      ],
    }
  }

}
