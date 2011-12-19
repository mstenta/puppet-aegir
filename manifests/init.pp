class aegir {

  package { 'aegir':
    ensure       => present,
    responsefile => 'files/aegir.preseed',
    require      => Class['aegir::dependencies'],
  }

  include apt

  apt::sources_list { "aegir-stable": content => "deb http://debian.aegirproject.org stable main" }
  apt::keys::key { "aegir": source => "puppet:///koumbit/debian.aegirproject.org.key" }

}
