class aegir::defaults {

  if ! $aegir_root { $aegir_root = '/var/aegir' }
  if ! $aegir_user { $aegir_user = 'aegir' }

  Exec { path        => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
         user        => $aegir_user,
         group       => $aegir_user,
         environment => "HOME=${aegir_root}",
  }

}
