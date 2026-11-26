node default {
  $role = $facts['server_role']

  if $role == 'portal' {
    include portal_web
  } elsif $role == 'nagios' {
    include nagios_server
  } else {
    notify { 'Unknown server_role fact; skipping role configuration.': }
  }
}
