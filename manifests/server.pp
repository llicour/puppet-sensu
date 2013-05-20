# Sensu monitoring server
# cf http://sensuapp.org/

class sensu::server ( $up = true,
                      $dashboard_user     = "admin",
                      $dashboard_password = "plokiploki",
 ) inherits sensu {

    include rabbitmq
    include redis

    rabbitmq_vhost { '/sensu' :
        ensure   => present,
        provider => 'rabbitmqctl',
    }

    rabbitmq_user { "$sensu::mqsrv_user" :
        admin     => true,
        password  => $sensu::mqsrv_password,
        provider  => 'rabbitmqctl',
    }

    rabbitmq_user_permissions { 'sensu@/sensu' :
        require              => [ Rabbitmq_vhost[ '/sensu' ],
                                  Rabbitmq_user[ "$sensu::mqsrv_user" ], ],
        configure_permission => '.*',
        read_permission      => '.*',
        write_permission     => '.*',
        provider             => 'rabbitmqctl',
    }

    $sensusrv = [ 'sensu-server', 'sensu-api', 'sensu-dashboard' ]

    file { 'server.json' :
        ensure  => present,
        path    => '/etc/sensu/conf.d/server.json',
        owner   => 'sensu',
        group   => 'sensu',
        mode    => '0640',
        content => template( 'sensu/conf.d/server.json' ),
        require => [ Package[ 'sensu' ],
                     File[ '/etc/sensu/conf.d' ], ],
        notify => [ Service[$sensusrv] ],
    }

    service { $sensusrv :
        ensure  => $up? { true    => running,
                          'true'  => running,
                          default => stopped },
        enable  => $up? { true    => true,
                          'true'  => true,
                          default => false },
        require => [  Package[ 'sensu' ],
                      Rabbitmq_user_permissions[ 'sensu@/sensu' ],
                      File[ 'server.json',
                            'checks.json','handlers.json' ], ],
    }

    file { '/root/sensu' :
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/root/sensu/sensu-restart.sh' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/sensu/admscripts/sensu-restart.sh',
        require => File[ '/root/sensu' ],
    }

    file { '/root/sensu/sensu-status.sh' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/sensu/admscripts/sensu-status.sh',
        require => File[ '/root/sensu' ],
    }

    file { '/root/sensu/sensu-admin.txt' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template( 'sensu/sensu-admin.txt' ),
        require => File[ '/root/sensu' ],
    }

/*
    include myfirewall

    firewall { '100 Sensu Dashboard' :
          chain  => 'INPUT',
          proto  => 'tcp',
          state  => 'NEW',
          dport  => '8181',
          action => 'accept',
    }

    firewall { '101 Sensu API' :
          chain  => 'INPUT',
          proto  => 'tcp',
          state  => 'NEW',
          dport  => '4567',
          action => 'accept',
    }
*/

}

