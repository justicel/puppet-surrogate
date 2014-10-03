# == Class: surrogate
#
# Main surrogate class which enables installation of surrogate and
# configuration of backups including cron based full/differential backups.
#
# === Parameters
#
# [*ensure*]
#   Set to absent or present to enable or disable the class installation.
# [*version*]
#   The git version to check out. Generally should be 'latest', but can also
#   be 'present' if you never want to update Surrogate code
# [*repo_location*]
#   Specify a git repository to use for surrogate source-code. Currently
#   goes to a default repository for surrogate fork, forked by Justice London.
# [*xtrabackup_config*]
#   Any extra xtrabackup performance flags will go here. Currently empty
# [*surrogate_home*]
#   Installation path for surrogate library
# [*logfile_path*]
#   Location to log output of backup jobs from Surrogate. Set by default
#   to the log folder under Surrogate home.
# [*surrogate_exec*]
#   The place to link the surrogate exec/script which by default is in local bin.
# [*repo_cache*]
#   Location to cache a copy of the Surrogate repository
# [*backup_user*]
#   Backup user specified in MySQL server. Documentation contains information on how
#   to create.
# [*backup_pass*]
#   Password for the backup user
# [*backup_folder*]
#   Location to store MySQL backups. By default places backups in /var/backups/mysql
# [*auto_rotate*]
#   Defines if the script should rotate/remove old backups or not
# [*days_retention*]
#   Number of days to keep 'daily' backups.
# [*weeks_retention*]
#   Number of weeks of weekly 'full' backups to keep.
# [*months_retention*]
#   Months of full, monthly backups to keep. By default keeps the last six months.
# [*weekly_day*]
#   The day of the week to run 'full' backups on. Defaults to Sunday.
# [*monthly_day*]
#   In date +%d format, the day of the month to run monthly backup on. Can be 01-31.
# [*schedule_backups*]
#   Enable or disable cron based backups for the server
# [*diff_backups*]
#   If daily differential/incremental backups should be run in addition to weekly
#   full backups.
# [*backup_hour*]
#   The hour in which to run full/inc backups on the MySQL server.
# [*backup_minute*]
#   Minute each day in addition to hour in which to run full/inc backups.
# [*diff_days*]
#   An array in FULL day-name format (Sunday, Monday, etc.) of days to run
#   differential/incremental backups.
# [*mysql_data*]
#   The location of mysql data folder. Generally pulled from params
# [*mysql_log*]
#   Log file path for mysql server
# [*mysql_socket*]
#   Socket file for mysql server which is pulled from server params.
#
# === Examples
#
#  class { surrogate:
#    ensure        => present,
#    backup_user   => 'dbbackup',
#    backup_pass   => 'mysecurepassword',
#    backup_folder => '/var/backups/mysql',
#  }
#
# === Authors
#
# Justice London <jlondon@syrussystems.com>
#
# === Copyright
#
# Copyright 2014 Justice London
#
class surrogate (
  $ensure           = present,
  $version          = latest,
  $repo_location    = 'https://github.com/justicel/surrogate.git',
  $xtraback_config  = template('surrogate/xtrabackup.conf.erb'),
  $surrogate_home   = '/usr/local/lib/surrogate',
  $logfile_path     = '/usr/local/lib/surrogate/log',
  $surrogate_exec   = '/usr/local/bin/surrogate',
  $repo_cache       = '/usr/local/src/surrogate',
  $backup_user      = '',
  $backup_pass      = '',
  $backup_folder    = '/var/backups/mysql',
  $auto_rotate      = 'true',
  $days_retention   = '7',
  $weeks_retention  = '4',
  $months_retention = '6',
  $weekly_day       = 'Sunday',
  $monthly_day      = '01',
  $schedule_backups = true,
  $diff_backups     = true,
  $backup_hour      = '3',
  $backup_minute    = '0',
  $diff_days        = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'],
  $mysql_data       = $::surrogate::params::mysql_data,
  $mysql_log        = $::surrogate::params::mysql_log,
  $mysql_socket     = $::surrogate::params::mysql_socket,
) inherits ::surrogate::params {
  include percona_repo

  #Include cron scheduling of jobs
  if $schedule_backups {
    include ::surrogate::cron
  }

  #Validate variables
  validate_absolute_path($surrogate_home)
  validate_absolute_path($surrogate_exec)
  validate_absolute_path($repo_cache)
  validate_absolute_path($mysql_data)
  validate_absolute_path($backup_folder)
  validate_absolute_path($logfile_path)
  validate_array($diff_days)
  validate_bool($diff_backups)
  validate_bool($schedule_backups)
  validate_re($ensure, '^(present|absent)$')
  validate_re($version, '^(present|latest|absent)$')
  validate_re($auto_rotate, '^(true|false)$')
  validate_re($weekly_day, '^(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)$')
  validate_re($days_retention, '^\d+$')
  validate_re($weeks_retention, '^\d+$')
  validate_re($months_retention, '^\d+$')
  validate_re($monthly_day, '^\d+$')
  validate_string($repo_location)
  validate_string($backup_user)
  validate_string($backup_pass)
  validate_string($auto_rotate)

  #Install repo of version, or set as absent
  $repo_version = $ensure ? {
    present => $version,
    default => absent
  }

  #Install required packages
  ensure_packages(['percona-xtrabackup', 'qpress'], { ensure => latest })

  #Create /usr/local/lib and /usr/backups as needed
  ensure_resource('file', ['/usr/local/lib', '/var/backups'], {
    'ensure' => 'directory'
  })
  #Create backup folder as needed
  ensure_resource('file', $backup_folder, {
    'ensure'  => 'directory',
    'require' => File['/var/backups'],
  })
  #Generate daily/weekly/monthly folders
  ensure_resource('file',
    [
      "${backup_folder}/daily",
      "${backup_folder}/weekly",
      "${backup_folder}/monthly",
    ],
    {
      'ensure'  => 'directory',
      'require' => File[$backup_folder],
    }
  )

  #Check out repo for surrogate
  vcsrepo { $repo_cache:
    ensure   => $repo_version,
    provider => git,
    source   => $repo_location,
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
    content => template('surrogate/surrogate.conf.erb'),
    require => File['/etc/surrogate'],
  }
  #Add extra configurations for xtrabackup
  file { '/etc/surrogate/xtrabackup.conf':
    ensure  => present,
    content => $xtraback_config,
    require => File['/etc/surrogate'],
  }

}
