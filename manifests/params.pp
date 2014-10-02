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
