define aegir::apt::debconf {
  exec { $name :
    command => "echo debconf ${name} | debconf-set-selections",
    path    => ['/bin', '/usr/bin' ],
  }
}
