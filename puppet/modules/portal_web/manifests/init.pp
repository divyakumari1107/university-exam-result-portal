# Class: portal_web
# Configures the Student Result Portal server:
#   1. Nginx web server + self-signed SSL certificate
#   2. Logrotate rules to prevent disk exhaustion during exam traffic
#   3. UFW firewall rules (HTTP, HTTPS, SSH, and NRPE)
#   4. Nagios NRPE agent + RAM/CPU/Disk/Nginx checks
#   5. Service enforcement for self-healing on drift

class portal_web {
  $doc_root       = '/var/www/result-portal'
  $ssl_cert_path  = '/etc/ssl/certs/result-portal.crt'
  $ssl_key_path   = '/etc/ssl/private/result-portal.key'
  $allowed_hosts  = pick($facts['nagios_allowed_subnet'], '127.0.0.1')
  $is_container   = pick($facts['is_container'], false)

  package { ['nginx', 'ufw', 'logrotate', 'openssl', 'nagios-nrpe-server', 'nagios-plugins']:
    ensure => installed,
  }

  # Generate self-signed SSL cert idempotently for HTTPS standardization
  exec { 'generate_portal_ssl':
    command => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_key_path} -out ${ssl_cert_path} -subj '/C=IN/ST=State/L=City/O=StateUniversity/CN=result-portal.local'",
    creates => $ssl_cert_path,
    require => Package['openssl'],
    notify  => Service['nginx'],
  }

  file { $doc_root:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0755',
  }

  file { "${doc_root}/index.html":
    ensure  => file,
    source  => 'puppet:///modules/portal_web/index.html',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    require => File[$doc_root],
  }

  file { "${doc_root}/health.html":
    ensure  => file,
    source  => 'puppet:///modules/portal_web/health.html',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    require => File[$doc_root],
  }

  file { "${doc_root}/students.json":
    ensure  => file,
    source  => 'puppet:///modules/portal_web/students.json',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    require => File[$doc_root],
  }

  # Disable default Nginx site and apply standardized portal vhost
  file { '/etc/nginx/sites-enabled/default':
    ensure  => absent,
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  file { '/etc/nginx/sites-available/result-portal.conf':
    ensure  => file,
    content => template('portal_web/portal.conf.erb'),
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  file { '/etc/nginx/sites-enabled/result-portal.conf':
    ensure  => link,
    target  => '/etc/nginx/sites-available/result-portal.conf',
    require => File['/etc/nginx/sites-available/result-portal.conf'],
    notify  => Service['nginx'],
  }

  # Standardize log rotation so exam-day access logs never fill up the disk
  file { '/etc/logrotate.d/result-portal-nginx':
    ensure  => file,
    content => template('portal_web/logrotate_nginx.erb'),
    mode    => '0644',
    require => Package['logrotate'],
  }

  # Custom lightweight RAM check script for Nagios NRPE (Critical > 85%)
  file { '/usr/local/bin/check_ram.sh':
    ensure  => file,
    mode    => '0755',
    content => "#!/bin/bash\nUSED_PCT=\$(free | awk '/Mem:/ {printf \"%.0f\", \$3/\$2 * 100}')\nif [ \"\$USED_PCT\" -gt 85 ]; then\n  echo \"CRITICAL - Memory usage is \${USED_PCT}% (>85%)\"\n  exit 2\nelif [ \"\$USED_PCT\" -ge 75 ]; then\n  echo \"WARNING - Memory usage is \${USED_PCT}%\"\n  exit 1\nelse\n  echo \"OK - Memory usage is \${USED_PCT}%\"\n  exit 0\nfi\n",
  }

  # Configure NRPE checks and allow monitoring host
  file { '/etc/nagios/nrpe.d/portal_checks.cfg':
    ensure  => file,
    content => template('portal_web/nrpe_portal.cfg.erb'),
    mode    => '0644',
    require => [Package['nagios-nrpe-server'], File['/usr/local/bin/check_ram.sh']],
    notify  => Service['nagios-nrpe-server'],
  }

  # Standardize UFW firewall rules (skip inside Docker containers without kernel netfilter)
  if !$is_container {
    exec { 'ufw_allow_rules':
      command => '/usr/sbin/ufw allow 22/tcp && /usr/sbin/ufw allow 80/tcp && /usr/sbin/ufw allow 443/tcp && /usr/sbin/ufw allow 5666/tcp && /usr/sbin/ufw --force enable',
      unless  => '/usr/sbin/ufw status | /bin/grep -q "Status: active"',
      require => Package['ufw'],
    }
  }

  $svc_provider = $is_container ? { true => 'debian', default => undef }

  # Enforce running services (enables automatic recovery if Nginx stops)
  service { 'nginx':
    ensure   => running,
    enable   => true,
    provider => $svc_provider,
    require  => [Package['nginx'], File['/etc/nginx/sites-enabled/result-portal.conf']],
  }

  service { 'nagios-nrpe-server':
    ensure   => running,
    enable   => true,
    provider => $svc_provider,
    require  => Package['nagios-nrpe-server'],
  }
}
