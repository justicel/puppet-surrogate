# == Class: surrogate
#
# Full description of class surrogate here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { surrogate:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class surrogate (
  $ensure           = present,
  $version          = latest,
  $repo_location    = 'https://github.com/justicel/surrogate.git',
  $surrogate_home   = '/usr/local/lib/surrogate',
  $surrogate_exec   = '/usr/local/bin/surrogate',
  $repo_cache       = '/usr/local/src/surrogate',
  $backup_user      = '',
  $backup_pass      = '',
  $backup_folder    = '/var/backups/mysql',
  $auto_rotate      = 'true',
  $days_retention   = '7',
  $weeks_retention  = '4',
  $months_retention = '6',
  $weekly_day       = 'Sun',
  $monthly_day      = '1',
  $diff_backups     = true,
  $backup_hour      = '3',
  $backup_minute    = '0',
  $diff_days        = ['Mon','Tue','Wed','Thu','Fri','Sat'],
  $mysql_data       = $::surrogate::params::mysql_data,
  $mysql_log        = $::surrogate::params::mysql_log,
  $mysql_socket     = $::surrogate::params::mysql_socket,
) inherits ::surrogate::params {

  #Validate variables
  validate_absolute_path([
    $surrogate_home,
    $surrogate_exec,
    $repo_cache,
    $mysql_socket,
    $mysql_data,
    $mysql_log,
    $backup_folder
  ])
  validate_array($diff_days)
  validate_bool($diff_backups)
  validate_re($ensure, '^(present|absent)$')
  validate_re($version, '^(present|latest|absent)$')
  validate_re($auto_rotate, '^(true|false)$')
  validate_re($weekly_day, '^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)$')
  validate_re(
    [
      $days_retention,
      $weeks_retention,
      $months_retention,
      $monthly_day,
    ],
    '^[0-9]*$',
  )
  validate_string([
    $repo_location,
    $backup_user,
    $backup_pass,
    $auto_rotate,
  ])

  #Install repo of version, or set as absent
  $repo_version = $ensure ? {
    present => $version,
    default => absent
  }

  #Install git as needed
  ensure_packages(['git'])

  #Create /usr/local/lib and /usr/backups as needed
  ensure_resource('file', ['/usr/local/lib', '/usr/backups'], {
    'ensure' => 'directory'
  })
  #Create backup folder as needed
  ensure_resource('file', $backup_folder, {
    'ensure'  => 'directory',
    'require' => File['/usr/backups'],
  })

  #Check out repo for surrogate
  vcsrepo { $repo_cache:
    ensure   => $repo_version,
    provider => git,
    source   => $repo_location,
    require  => Package['git'],
  }

  #Generate file link for surrogate lib
  file { $surrogate_home:
    ensure  => link,
    target  => "${repo_cache}/files",
    require => [File['/usr/local/lib'], Vcsrepo[$repo_cache]],
  }
  #Link the surrogate exec
  file { $surrogate_exec:
    ensure  => link,
    target  => "${surrogate_home}/surrogate",
    require => File[$surrogate_home],
  }
  #Conf folder. Static link as surrogate requires /etc/surrogate for conf
  file { '/etc/surrogate':
    ensure  => directory,
    require => Vcsrepo[$repo_cache],
  }

  #Build the surrogate configuration file
  file { '/etc/surrogate/surrogate.conf':
    ensure  => present,
    content => 'puppet:///modules/surrogate/surrogate.conf.erb',
    require => File['/etc/surrogate'],
  }

}
