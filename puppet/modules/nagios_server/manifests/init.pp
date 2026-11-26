# Class: nagios_server
# Installs and configures Nagios 4 + Apache2 to monitor the Student Result Portal.

class nagios_server {
  $portal_ip          = pick($facts['portal_server_ip'], '127.0.0.1')
  $exam_season_active = pick($facts['exam_season_active'], true)
  $admin_pass         = pick($facts['nagios_admin_password'], 'ExamPortal@2026')
  $admin_email        = pick($facts['admin_email'], 'admin@university.local')
  $alert_webhook_url  = pick($facts['alert_webhook_url'], '')
  $is_container       = pick($facts['is_container'], false)
  $svc_provider       = $is_container ? { true => 'debian', default => undef }

  package { ['nagios4', 'nagios-plugins', 'nagios-nrpe-plugin', 'apache2', 'apache2-utils', 'libapache2-mod-php', 'curl', 'bsd-mailx']:
    ensure => installed,
  }

  # Real-time Slack / Discord / Telegram webhook alert dispatcher for Nagios
  file { '/usr/local/bin/notify_webhook.sh':
    ensure  => file,
    mode    => '0755',
    content => "#!/bin/bash\nWEBHOOK_URL=\"${alert_webhook_url}\"\n[ -z \"\$WEBHOOK_URL\" ] && exit 0\nMSG=\"\$1\"\nESCAPED=\$(printf '%s' \"\$MSG\" | sed 's/\"/\\\\\"/g')\nif echo \"\$WEBHOOK_URL\" | grep -q \"api.telegram.org\"; then\n  curl -sS -X POST \"\$WEBHOOK_URL\" -H \"Content-Type: application/json\" -d \"{\\\"text\\\": \\\"\$ESCAPED\\\"}\" >/dev/null || true\nelse\n  curl -sS -X POST \"\$WEBHOOK_URL\" -H \"Content-Type: application/json\" -d \"{\\\"text\\\": \\\"\$ESCAPED\\\", \\\"content\\\": \\\"\$ESCAPED\\\"}\" >/dev/null || true\nfi\n",
    require => Package['curl'],
  }

  # Enable required Apache modules for Nagios 4 web dashboard
  exec { 'enable_nagios_apache_modules':
    command => '/usr/sbin/a2enmod authz_groupfile auth_digest cgi',
    unless  => '/usr/sbin/apache2ctl -M | /bin/grep -q cgi_module',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }

  # Set nagiosadmin Digest auth entry non-interactively (matches Ubuntu nagios4 AuthName "Nagios4")
  exec { 'set_nagios_admin_password':
    command => "/bin/bash -c 'HASH=$(printf \"nagiosadmin:Nagios4:${admin_pass}\" | /usr/bin/md5sum | /usr/bin/awk \"{print \\$1}\"); printf \"nagiosadmin:Nagios4:%s\\n\" \"\$HASH\" > /etc/nagios4/htdigest.users'",
    require => Package['nagios4'],
    notify  => Service['apache2'],
  }

  # Deploy Nagios host & service checks when exam season is active
  file { '/etc/nagios4/conf.d/portal_host.cfg':
    ensure  => $exam_season_active ? { true => file, default => absent },
    content => template('nagios_server/portal_host.cfg.erb'),
    mode    => '0644',
    require => Package['nagios4'],
    notify  => Service['nagios4'],
  }

  service { 'apache2':
    ensure   => running,
    enable   => true,
    provider => $svc_provider,
    require  => Package['apache2'],
  }

  service { 'nagios4':
    ensure   => running,
    enable   => true,
    provider => $svc_provider,
    require  => [Package['nagios4'], File['/etc/nagios4/conf.d/portal_host.cfg']],
  }
}
