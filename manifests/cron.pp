class surrogate::cron (
  $ensure        = present,
  $diff_backups  = true,
  $backup_hour   = 3,
  $backup_minute = 0,
  $backup_day    = 'Sun',
  $diff_days     = ['Mon','Tue','Wed','Thu','Fri','Sat'],
) {
  validate_array($diff_days)
  validate_bool($diff_backups)
  validate_re($ensure, '^(present|absent)$')
  validate_re([$backup_hour, $backup_minute], '^[0-9]*$')
  validate_re($backup_day, '^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)$')

  #Be safe and remove backup day from diff days if someone still added it
  $diff_days_true = inline_template('<%= (@diff_days - [@backup_day]).join(',') %>')

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
