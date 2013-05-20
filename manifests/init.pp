# Inspired by :
# https://github.com/joemiller/joemiller.me-intro-to-sensu
# http://joemiller.me/2012/02/02/sensu-and-graphite/

class sensu(  $mqsrv='el6a.labolinux.fr',
              $mqsrv_user    ='sensu',
              $mqsrv_password='plokiploki',
              $repo='http://repos.sensuapp.org/yum/el/$release/$arch' ) {

    yumrepo { 'sensu' :
        baseurl  => $repo,
        descr    => 'sensu',
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

    # SSL certificates generated from autopki
    file { '/etc/sensu/ssl/cacert.pem' :
        ensure  => present,
        path    => '/etc/sensu/ssl/cacert.pem',
        owner   => 'sensu',
        group   => 'sensu',
        mode    => '0644',
        source  => "puppet:///private/rabbitmq/cacert.pem",
        require => File[ '/etc/sensu/ssl' ],
        notify => Service["sensu-client"],
    }
    file { '/etc/sensu/ssl/client_cert.pem' :
        ensure  => present,
        path    => '/etc/sensu/ssl/client_cert.pem',
        owner   => 'sensu',
        group   => 'sensu',
        mode    => '0644',
        source  => "puppet:///private/rabbitmq/client_cert.pem",
        require => File[ '/etc/sensu/ssl' ],
        notify => Service["sensu-client"],
    }
    file { '/etc/sensu/ssl/client_key.pem' :
        ensure  => present,
        path    => '/etc/sensu/ssl/client_key.pem',
        owner   => 'sensu',
        group   => 'sensu',
        mode    => '0400',
        source  => "puppet:///private/rabbitmq/client_key.pem",
        require => File[ '/etc/sensu/ssl' ],
        notify => Service["sensu-client"],
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
        notify => Service["sensu-client"],
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
        require   => [  Package[ 'sensu' ],
                        File[ '/etc/sensu/ssl/client_key.pem',
                              '/etc/sensu/ssl/client_cert.pem',
                              'client.json',
                              'checks.json',
                              'handlers.json' ], ],
    }
}

