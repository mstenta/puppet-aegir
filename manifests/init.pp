class aegir {

  if ! ($aegir_manual_build or $aegir_dev_build) {
    include aegir::frontend
  }
  else {
    include aegir::manual_build
  }

  include aegir::login_link

}

class aegir::frontend {
  include aegir::backend

  Exec { before  => Package['aegir'], }
  if $aegir_site {        exec {"echo debconf aegir/site string $aegir_site | debconf-set-selections": } }
  if $aegir_db_host {     exec {"echo debconf aegir/db_host string $aegir_db_host | debconf-set-selections": } }
  if $aegir_db_user {     exec {"echo debconf aegir/db_user string $aegir_db_user | debconf-set-selections": } }
  if $aegir_db_password { exec {"echo debconf aegir/db_password string $aegir_db_password | debconf-set-selections": } }
  if $aegir_email {       exec {"echo debconf aegir/email string $aegir_email | debconf-set-selections": } }
  if $aegir_makefile {    exec {"echo debconf aegir/makefile string $aegir_makefile | debconf-set-selections": } }

  package { 'aegir':
    ensure       => present,
    responsefile => 'files/aegir.preseed',
    require      => Apt::Sources_list['aegir-stable'], 
    notify       => Exec['login link'],
  }

}

class aegir::backend {
  include drush
  include aegir::apt

  package { 'aegir-provision':
    ensure  => present,
    require => [ Apt::Sources_list['aegir-stable'], 
                 Package['drush'],
               ],
  }
}


class aegir::apt {
  include apt

  apt::sources_list { "aegir-stable":
    content => "deb http://debian.aegirproject.org stable main",
    require => Apt::Keys::Key['aegir'],
  }
  apt::keys::key { "aegir": source => "puppet:///modules/aegir/debian.aegirproject.org.key" }
}
