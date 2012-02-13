define aegir::platform ($makefile, $options = "", $platforms_dir = "/var/aegir/platforms") {

  $alias_dir = '/var/aegir/.drush'

  Exec { path        => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
         user        => 'aegir',
         group       => 'aegir',
         environment => "HOME=/var/aegir",
  }

  exec {"provision-save-${name}":
    command => "drush --root=${platforms_dir}/${name} --context_type='platform' --makefile='${makefile}' provision-save @platform_${name}",
    creates => "${alias_dir}/platform_${name}.alias.drushrc.php",
    require => Class['aegir::backend'],
  }

  exec {"hosting-import-${name}":
    command => "drush @hostmaster hosting-import @platform_${name}",
    creates => "${platforms_dir}/${name}",
    require => [ Exec["provision-save-${name}"], 
                 Class['aegir::frontend'],
               ],
  }
                          
}
