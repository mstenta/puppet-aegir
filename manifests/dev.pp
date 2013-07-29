class aegir::dev (
  $frontend_url = $aegir::defaults::frontend_url,
  $db_host      = $aegir::defaults::db_host,
  $db_user      = $aegir::defaults::db_user,
  $db_password  = $aegir::defaults::db_password,
  $admin_email  = $aegir::defaults::admin_email,
  $admin_name   = $aegir::defaults::admin_name,
  $makefile     = $aegir::defaults::makefile,
  $apt          = $aegir::defaults::apt,
  $aegir_user   = $aegir::defaults::aegir_user,
  $aegir_root   = $aegir::defaults::aegir_root,
  $web_group    = $aegir::defaults::web_group,
  $db_server    = $aegir::defaults::db_server,
  $web_server   = $aegir::defaults::web_server,
  $update       = false,
  $drush_make_version = false,
  $hostmaster_repo    = 'http://git.drupal.org/project/hostmaster.git',
  $hostmaster_branch  = '7.x-3.x',
  $provision_repo     = 'http://git.drupal.org/project/provision.git',
  $provision_branch   = '7.x-3.x'
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
    git_branch => $provision_branch,
    dir_name   => 'provision',
    path       => "${aegir_root}/.drush/",
    require    => File[ $aegir_root, "${aegir_root}/.drush"],
    update     => $update,
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_system_requirements
  if $apt {

    package { ['php5', 'php5-cli', 'php5-gd', 'php5-mysql', 'postfix', 'sudo', 'rsync',/* 'git-core',*/ 'unzip']:
      ensure  => present,
      require => Exec['aegir_update_apt'],
      before  => Drush::Run['hostmaster-install'],
    }

    package { $web_server :
      ensure  => present,
      require => Exec['aegir_update_apt'],
      before  => [
        User[$aegir_user],
        Drush::Run['hostmaster-install'],
      ],
    }

    exec { 'aegir_update_apt':
      command     => '/usr/bin/apt-get update',
      refreshonly => true,
      subscribe   => Exec['Install provision'],
    }

  }

  case $web_server {
    # Ref.: http://community.aegirproject.org/installing/manual#Nginx_configuration
    'nginx': {
      $http_service_type = 'apache'
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
    content => 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl\naegir ALL=NOPASSWD: /etc/init.d/nginx\n',
    mode    => '0440',
    before  => Drush::Run['hostmaster-install'],
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#DNS_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Database_configuration
  if $apt {
    case $db_server {
      'mysql': {
        package {'mysql-server':
          ensure  => present,
          require => Exec['update_apt'],
          before  => Drush::Run['hostmaster-install'],
        }
      }
      #'mariadb': { /* To do */ }
      #'postgresql': { /* To do */ }
      default: {
        err("'${db_server}' is not a supported web server. Supported web servers include 'mysql'.")
      }
    }
  }

  # Note: Skipping the below (for now)
  # comment out 'bind-address = 127.0.0.1' from /etc/mysql/my.cnf
  # exec /etc/init.d/mysql restart

  # Ref.: http://community.aegirproject.org/installing/manual#Running_hostmaster-install

  # Build our options
  $default_options = " --debug --working-copy --strict=0 --no-gitinfofile --aegir_version=${hostmaster_branch}"
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
  $install_options = "$default_options${a}${b}${c}${d}${e}${f}${g}${h}${i}${j}${k}${l}"

  drush::run {'hostmaster-install':
    arguments   => $frontend_url,
    options     => $install_options,
    log         => '/var/aegir/install.log',
    creates     => "${aegir_root}/hostmaster-${hostmaster_branch}",
    require     => User[$aegir_user],
    timeout     => 0,
  }

  if $update {
    $hostmaster_dir = "${aegir_root}/hostmaster-${hostmaster_branch}/profiles/hostmaster"
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
