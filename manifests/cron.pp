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
  validate_re($backup_day, '^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)$')

  #Be safe and remove backup day from diff days if someone still added it
  $diff_days_true = join(delete($diff_days, $backup_day), ',')

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
