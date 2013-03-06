# Inspired by :
# https://github.com/joemiller/joemiller.me-intro-to-sensu
# http://joemiller.me/2012/02/02/sensu-and-graphite/

class sensu( $mqsrv='el6a.labolinux.fr' ) {

    yumrepo { 'sensu' :
        baseurl  =>
              'http://repos.sensuapp.org/yum/el/$releasever/$basearch/',
        descr    => 'sensu-main',
        enabled  => 1,
        gpgcheck => 0,
    }

    package { 'sensu' :
        ensure  => present,
        require => Yumrepo[ 'sensu' ],
    }

    file { '/etc/sensu/ssl' :
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package[ 'sensu' ],
    }

    # You can generate the CA and the key with helper scripts from
    # git://github.com/joemiller/joemiller.me-intro-to-sensu.git

    file { 'client_cert.pem' :
        ensure  => present,
        path    => '/etc/sensu/ssl/client_cert.pem',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/sensu/ssl/client_cert.pem',
        require => File[ '/etc/sensu/ssl' ],
    }

    file { 'client_key.pem' :
        ensure  => present,
        path    => '/etc/sensu/ssl/client_key.pem',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/sensu/ssl/client_key.pem',
        require => File[ 'client_cert.pem' ],
    }


    file { 'config.json' :
        ensure  => present,
        path    => '/etc/sensu/config.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template( 'sensu/config.json' ),
        require => Package[ 'sensu' ],
    }

    file { '/etc/sensu/conf.d' :
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package[ 'sensu' ],
    }

    file { 'client.json' :
        ensure  => present,
        path    => '/etc/sensu/conf.d/client.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template( 'sensu/conf.d/client.json' ),
        require => File[ '/etc/sensu/conf.d' ],
    }

    file { 'checks.json' :
        ensure  => present,
        path    => '/etc/sensu/conf.d/checks.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/sensu/conf.d/checks.json',
        require => File[ '/etc/sensu/conf.d' ],
    }

    file { 'handlers.json' :
        ensure  => present,
        path    => '/etc/sensu/conf.d/handlers.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/sensu/conf.d/handlers.json',
        require => File[ '/etc/sensu/conf.d' ],
    }

    package { 'sensu-plugin' :
        ensure   => installed,
        provider => gem,
    }

    file { '/etc/sensu/plugins' :
        ensure  => directory,
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/sensu/plugins',
        require => Package[ 'sensu', 'sensu-plugin' ],
    }

    file { 'checks_crond.json' :
        ensure  => present,
        require => File[ '/etc/sensu/conf.d' ],
        path    => '/etc/sensu/conf.d/checks_crond.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/sensu/conf.d/checks_crond.json',
    }

    file { 'checks_sshd.json' :
        ensure  => present,
        require => File[ '/etc/sensu/conf.d' ],
        path    => '/etc/sensu/conf.d/checks_sshd.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/sensu/conf.d/checks_sshd.json',
    }

    file { 'handlers_graphite.json' :
        ensure  => present,
        require => File[ '/etc/sensu/conf.d' ],
        path    => '/etc/sensu/conf.d/handlers_graphite.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/sensu/conf.d/handlers_graphite.json',
    }

    file { 'metrics_vmstat.json' :
        ensure  => present,
        require => File[ '/etc/sensu/conf.d' ],
        path    => '/etc/sensu/conf.d/metrics_vmstat.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/sensu/conf.d/metrics_vmstat.json',
    }

    service { 'sensu-client' :
        ensure    => running,
        enable    => true,
        require   => [  Package[ 'sensu', 'sensu-plugin' ],
                        File[ 'client_key.pem','config.json','client.json',
                              'checks.json','handlers.json' ], ],
    }
}

