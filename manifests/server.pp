class sensu::server ( $up = hiera('sensu::server::up', true) ) inherits sensu {

    include rabbitmq
    include redis

    rabbitmq_vhost { '/sensu' :
        ensure   => present,
        provider => 'rabbitmqctl',
    }

    rabbitmq_user { 'sensu' :
        admin     => true,
        password  => 'plokiploki',
        provider  => 'rabbitmqctl',
    }

    rabbitmq_user_permissions { 'sensu@/sensu' :
        require              => [ Rabbitmq_vhost[ '/sensu' ],
                                  Rabbitmq_user[ 'sensu' ], ],
        configure_permission => '.*',
        read_permission      => '.*',
        write_permission     => '.*',
        provider             => 'rabbitmqctl',
    }

    $sensusrv = [ 'sensu-server', 'sensu-api', 'sensu-dashboard' ]

    service { $sensusrv :
        ensure  => $up? { true    => running,
                          'true'  => running,
                          default => stopped },
        enable  => $up? { true    => true,
                          'true'  => true,
                          default => false },
        require => [  Package[ 'sensu', 'sensu-plugin' ],
                      Rabbitmq_user_permissions[ 'sensu@/sensu' ],
                      File[ 'client_key.pem','config.json','client.json',
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
}

