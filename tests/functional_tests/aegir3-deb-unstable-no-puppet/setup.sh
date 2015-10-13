#!/bin/bash

CWD=`pwd`
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if [ ! -h $SCRIPT_DIR/../../../Vagrantfile ]
then
  ln -s $SCRIPT_DIR/Vagrantfile $SCRIPT_DIR/../../../Vagrantfile
fi

if [ -e $CWD/.vagrant ]
then
  cd $CWD && vagrant destroy --force
fi
