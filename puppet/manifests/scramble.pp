# vim: ft=puppet ts=2 sw=2 et

# Todos os pacotes deverão estar instalados
Package {
  ensure => "latest",
  require => Exec['apt-get update']
}

Exec {
  path	=> "/usr/local/bin:/bin:/usr/bin",
}

exec { "apt-get update" :
  onlyif => "/bin/sh -c '[ ! -f /var/cache/apt/pkgcache.bin ] || /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null'"
}

$scramble_depencies = [ "markdown", "make", "gcc", "git", "mercurial", "mysql-server" ]
package { $scramble_depencies : }

# Go installation
exec { "download-go" :
  command => "/usr/bin/wget https://go.googlecode.com/files/go1.1.2.linux-amd64.tar.gz -O go.tar.gz",
  cwd	    => "/home/vagrant",
  creates => "/home/vagrant/go.tar.gz",
  timeout => 0,
  user    => "vagrant"
}

exec { "extract-go" :
  command => "tar -xvf go.tar.gz",
  cwd	    => "/home/vagrant",
  creates => "/usr/local/go",
  user    => "vagrant",
  require => Exec['download-go']
}

exec { "install-go" :
  command => "mv -f go /usr/local/; ln -sf /usr/local/go/bin/* /usr/local/bin/",
  creates => "/usr/local/bin/go",
  cwd	    => "/home/vagrant",
  require => Exec['extract-go']
}

# Scramble repository clone
exec { "download-scramble":
  command => "git clone https://github.com/dcposch/scramble",
  creates => "/home/vagrant/scramble",
  user    => "vagrant",
  require => Package['git']
}

exec { "install-scramble":
  command     => "make",
  cwd         => "/home/vagrant/scramble",
  creates     => "/home/vagrant/scramble/bin/scramble",
  user        => "vagrant",
  environment => ["GOPATH=/home/vagrant/scramble/src", "HOME=/home/vagrant"],
  returns     => [0, 2],
  require     => [Exec['download-scramble'], Package['markdown'], Exec['install-go']]
}

exec { "mysql-root-password":
  command => "sudo mysqladmin -u root password root",
  returns => [0, 1],
  require => Package['mysql-server']
}

file { "mysqluser-scramble-script":
  path    => "/home/vagrant/scramble/mysql-user.sql",
  ensure  => file,
  owner   => "vagrant",
  source  => "puppet:///modules/scramble/scramble.sql",
  require => Exec['install-scramble']
}

exec { "mysql-script-scramble":
  cwd     => "/home/vagrant/scramble",
  command => "mysql -u root -p'root' < mysql-user.sql",
  user    => "vagrant",
  require => [File['mysqluser-scramble-script'], Service['mysql']]
}

file { "config-scramble":
  path    => "/home/vagrant/.scramble/config.json",
  ensure  => file,
  source  => "puppet:///modules/scramble/config.json",
  owner   => "vagrant",
  require => Exec['install-scramble']
}

exec { "run-scramble":
  command     => "/home/vagrant/scramble/bin/scramble 2> /home/vagrant/scramble/scramble.log &",
  cwd         => "/home/vagrant/scramble",
  user        => "vagrant",
  environment => ["GOPATH=/home/vagrant/scramble/src", "HOME=/home/vagrant"],
  require     => [File['config-scramble'], Exec['mysql-script-scramble']]
}

# Bind9 DNS server
package { "bind9" :}

file { "/etc/bind/named.conf.default-zones" :
  ensure  => file,
  source  => "puppet:///modules/scramble/default-zones",
  require => Package['bind9']
}

file { "/etc/bind/db.local.scramble.io" :
  ensure  => file,
  source  => "puppet:///modules/scramble/db.local.scramble.io",
  require => Package['bind9']
}

file { "/etc/resolv.conf" :
  ensure   => file,
  content  => "nameserver\t127.0.0.1\n"
}

# Nginx configuration
package { "nginx" :}

service { "nginx" :
  ensure  => running,
  require => [ Package['nginx'], File['nginx-scramble']]
}

service { "mysql" :
  ensure  => running,
  require => Package['mysql-server']
}

file { "nginx-scramble" :
  path    => "/etc/nginx/sites-enabled/local.scramble.io",
  ensure  => file,
  source  => "puppet:///modules/scramble/nginx.local.scramble.io",
  require => Package['nginx']
}

file { "/etc/nginx/nginx.conf" :
  ensure  => file,
  source  => "puppet:///modules/scramble/nginx.conf",
  require => Package['nginx']
}

file { "/etc/ssl/local.scramble.io.crt" :
  ensure  => file,
  source  => "puppet:///modules/scramble/local.scramble.io.crt"
}

file { "/etc/ssl/local.scramble.io.key" :
  ensure  => file,
  source  => "puppet:///modules/scramble/local.scramble.io.key"
}
