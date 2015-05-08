vagrant up --provision
if [ "$?" -ne "0" ]
then
  echo "'vagrant up' failed. Leaving vm in place for forensic analysis."
  exit 1
fi

vagrant ssh -c "sudo -u root -s /bin/bash -c 'service hosting-queued stop'"
if [ "$?" -ne "0" ]
then
  echo "Could not stop the hosting-queued service. Leaving vm in place for forensic analysis."
  exit 1
fi

vagrant ssh -c "sudo -u root -s /bin/bash -c 'su aegir -l -c \"drush -y @hostmaster provision-tests-run\"'"
if [ "$?" -ne "0" ]
then
  echo "'provision-tests-run' failed. Leaving vm in place for forensic analysis."
  exit 1
fi

vagrant destroy --force
exit 0
