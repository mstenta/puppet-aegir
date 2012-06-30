class aegir::defaults {

  if ! $aegir_root { $aegir_root = '/var/aegir' }

  if ! $aegir_user { $aegir_user = 'aegir' }

  if ($aegir_dev_build and ! $aegir_version)   { $aegir_version = '6.x-1.x' }
  elsif ! $aegir_version { $aegir_version = '6.x-1.9' }

  if ! $aegir_hostmaster_url { $aegir_hostmaster_url = $fqdn }

  if ! $aegir_dev_build { $aegir_installed = Class['aegir::frontend'] }
  else { $aegir_installed = Class['aegir::manual_build::frontend'] }

  Exec { path        => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
         user        => $aegir_user,
         group       => $aegir_user,
         environment => "HOME=${aegir_root}",
         provider    => 'shell',
  }

}
