class aegir {
  include aegir::frontend
}

class aegir::frontend {
  include aegir::apt

  package { 'aegir':
    ensure       => present,
    responsefile => 'files/aegir.preseed',
  }
}

class aegir::backend {
  include aegir::apt

  package { 'aegir-provision': ensure => present }
}


class aegir::apt
  include apt

  apt::sources_list { "aegir-stable": content => "deb http://debian.aegirproject.org stable main" }
  apt::keys::key { "aegir": source => "puppet:///koumbit/debian.aegirproject.org.key" }
}
