#!/bin/bash

DRUSH_BRANCH='1.0.x'
AEGIR_BRANCH='1.0.x'
CWD=`pwd`
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d $SCRIPT_DIR/modules ]
then
  mkdir $SCRIPT_DIR/modules
fi

if [ -d $SCRIPT_DIR/modules/drush ]
then
  cd $SCRIPT_DIR/modules/drush && git pull
else
  git clone --branch $DRUSH_BRANCH http://git.drupal.org/project/puppet-drush.git $SCRIPT_DIR/modules/drush
fi

if [ -d $SCRIPT_DIR/modules/aegir ]
then
  cd $SCRIPT_DIR/modules/aegir && git pull
else
  git clone --branch $AEGIR_BRANCH http://git.drupal.org/project/puppet-aegir.git $SCRIPT_DIR/modules/aegir
fi

if [ ! -h $SCRIPT_DIR/../../../Vagrantfile ]
then
  ln -s $SCRIPT_DIR/Vagrantfile $SCRIPT_DIR/../../../Vagrantfile
fi

if [ -e $CWD/.vagrant ]
then
  cd $CWD && vagrant destroy --force
fi
