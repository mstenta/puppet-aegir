class aegir::mysql::preseed {

  file { 'preseedmysqlpass.sh':
    path => '/usr/local/sbin/preseedmysqlpass.sh',
    source => "puppet:///modules/aegir/scripts/preseedmysqlpass.sh",
    owner => root, group => 0, mode => 0500;
  }

  exec {'preseed mysql password':
    command => '/usr/local/sbin/preseedmysqlpass.sh',
    onlyif  => 'test -f /root/.my.cnf',
    require => File['preseedmysqlpass.sh'],
    before  => Package["aegir${aegir::real_api}"],
  }

}
