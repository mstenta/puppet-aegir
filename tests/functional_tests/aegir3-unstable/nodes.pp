node "aegir3-unstable" {

  class { 'aegir' :
    api     => 3,
    dist    => 'unstable',
  }

}
