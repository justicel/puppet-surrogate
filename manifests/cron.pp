# == Class: surrogate::cron
#
# The cron creation for backups of Surrogate class.
# Takes in specific days/times for backups and
# Generates either full or diff backups of database
#
# === Parameters
#
# [*ensure*]
#   Either present or absent. Will remove or add the
#   cron entries depending on ensure state.
# [*diff_backups*]
#   Set to true or false to enable or disable daily
#   differential backups of mysql server. Will need a
#   single full backup run before differential backups
#   can run.
# [*backup_hour*]
#   The hour (0-24) in which to run the backups
# [*backup_minute*]
#   Minute (0-60) in which to run backups
# [*backup_day*]
#   The day to run a FULL backup (Monday-Sunday)
# [*diff_days*]
#   An array of days in FULL text form of days to
#   run incremental backups 
#   ex: ['Monday', 'Wednesday', 'Friday']
#
# === Examples
#
#  class { surrogate::cron:
#    ensure        => present,
#    diff_backups  => true,
#    backup_hour   => '1',
#    backup_minute => '0',
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
class surrogate::cron (
  $ensure        = $::surrogate::ensure,
  $diff_backups  = $::surrogate::diff_backups,
  $backup_hour   = $::surrogate::backup_hour,
  $backup_minute = $::surrogate::backup_minute,
  $backup_day    = $::surrogate::weekly_day,
  $diff_days     = $::surrogate::diff_days,
) {
  validate_array($diff_days)
  validate_bool($diff_backups)
  validate_re($ensure, '^(present|absent)$')
  validate_re($backup_hour, '^\d+$')
  validate_re($backup_minute, '^\d+$')
  validate_re($backup_day, '^(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)$')

  #Be safe and remove backup day from diff days if someone still added it
  $diff_days_true = delete($diff_days, $backup_day)

  #Enable cron for surrogate
  cron { 'surrogate_full':
    ensure      => $ensure,
    command     => 'surrogate -b full',
    environment => [ 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin' ],
    hour        => $backup_hour,
    minute      => $backup_minute,
    weekday     => $backup_day
  }

  if $diff_backups {
    cron { 'surrogate_diff':
      ensure      => $ensure,
      command     => 'surrogate -b inc',
      environment => [ 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin' ],
      hour        => $backup_hour,
      minute      => $backup_minute,
      weekday     => $diff_days_true,
    }
  }

}
