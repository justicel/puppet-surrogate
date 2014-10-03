# == Class: surrogate::params
#
# The parameters class for surrogate. Currently grabs OS
# variables and supports RedHat or Debian. Further OS
# support can be added in the future or by submitting a
# pull request!
#
# === Authors
#
# Justice London <jlondon@syrussystems.com>
#
# === Copyright
#
# Copyright 2014 Justice London
#
class surrogate::params {

  case $::osfamily {
    'RedHat': {
      $mysql_socket = '/var/lib/mysql/mysql.sock'
      $mysql_data   = '/var/lib/mysql'
      $mysql_log    = '/var/lib/mysql/error.log'

    }
    'Debian': {
      $mysql_socket = '/var/run/mysqld/mysqld.sock'
      $mysql_data   = '/var/lib/mysql'
      $mysql_log    = '/var/log/mysql/error.log'
    }
    default: {
      fail("Class['surrogate::params']: Unsupported OS: ${::osfamily}")
    }
  }

}
