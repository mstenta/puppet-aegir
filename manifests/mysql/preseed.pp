class aegirvps::mysql::preseed {

  file { 'preseedmysqlpass.sh':
    path => '/usr/local/sbin/preseedmysqlpass.sh',
    source => "puppet:///modules/aegirvps/scripts/preseedmysqlpass.sh",
    owner => root, group => 0, mode => 0500;
  }

  exec {'preseed mysql password':
    command => '/usr/local/sbin/preseedmysqlpass.sh',
    require => File['preseedmysqlpass.sh'],
    before  => Package['aegir'],
  }

}
