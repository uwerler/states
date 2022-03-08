# NSD

This state generates zone files and the configuration for nsd out of pillar
data. If soa option serial is set to auto a new serial will be generated on
each zone update. The idea is stolen from bind-formula and also the jinja
template for the generation of the reverse zone.

Options can be globally specified under nsd:config:master or nsd:config:slave
or per zone basis nsd:zones:zonename:master.

For state application the minion.id must match either the configured master:name or one
of the slave:names.

This is the "first shot" to generate a salt-formula. I use nsd usually under
OpenBSD but tested that also under Debian and Ubuntu. More work has to be done
to create a proper map.jinja.

## Sample pillar:

```
nsd:
  config:
    zones_directory: '/tmp'
    config_file: /etc/nsd/nsd.conf
    master:
      name: mymaster.example.com
      options:
        notify:        192.168.1.2@5300 tsig.key
        provide-xfr:   192.168.1.2      tsig.key
      config:
        server:
          hide-version: yes
          verbosity: 1
          database: '""' # disable database
          #ip-address: lo0@5300
          #ip-address: vmx0@5300
          port: 5300
        remote-control:
          control-enable: yes
          control-interface: /var/run/nsd.sock
        key:
          name:          "tsig.key"
          algorithm:     hmac-sha256
          secret:        "jG6N7ddCgWWQzARN38CpOddFm5CA3qEqVqXtGhbd8gN9TUlK6YLJLRFkEH3LWj9i"
        include: /etc/nsd.conf.d/*.conf
    slave:
      name: myslave.example.com
      options:
        allow-notify:  192.168.1.1      tsig.key
        request-xfr:   192.168.1.1@5300 tsig.key
    soa:                                        # Declare the SOA RRs for the zone
      ns: mymaster.example.com.                 # Required
      contact: support.example.com.             # Required
      serial: auto                              # Alternatively, autoupdate serial on each change
      class: IN                                 # Optional. Default: IN
      refresh: 900                              # Optional. Default: 12h
      retry: 600                                # Optional. Default: 15m
      expiry: 8640                              # Optional. Default: 2w
      nxdomain: 500                             # Optional. Default: 1m
      ttl: 1800                                 # Optional. Not set by default

```

## Sample zone pillar:

```
  zones:
    example.com:
      records:                                  # Records for the zone, grouped by type
        NS:
          '@':
            - mymaster
            - myslave
        CNAME:
          dns01: mymaster
          dns02: myslave
        TXT:                                    # Complex records can be expressed as strings
          '@':
            - '"some_value"'
            - '"v=spf1 mx a ip4:1.2.3.4 ~all"'
          _dmarc: '"v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; fo=1:d:s; adkim=r; aspf=r; pct=100; ri=86400"'
        SRV:
          _kerberos._tcp.dc._msdcs:
            - '0 0 88       dc01.example.com.'
          _ldap._tcp.dc._msdcs:
            - '0 0 389      dc01.example.com.'
    master:
      options:
        allow-notify:  192.168.1.1      tsig.ec4sap.amag.car.web
        request-xfr:   192.168.1.1@5300 tsig.ec4sap.amag.car.web
    soa:                                        # Declare the SOA RRs for the zone
      ns: mymaster.example.com.                 # Required
      contact: support.example.com.             # Required
      serial: auto                              # Alternatively, autoupdate serial on each change
      class: IN                                 # Optional. Default: IN
      refresh: 900                              # Optional. Default: 12h
      retry: 600                                # Optional. Default: 15m
      expiry: 8640                              # Optional. Default: 2w
      nxdomain: 500                             # Optional. Default: 1m
      ttl: 1800                                 # Optional. Not set by default

    1.168.192.in-addr.arpa:                     # auto-generated reverse zone
      records:                                  # Records for the zone, grouped by type
        NS:
          '@':
            - mymaster.example.com.
            - myslave.example.com.
      generate_reverse:                         # take all A records from example.com that are
        net: 192.168.1.0/24                     # in subnet 192.168.1.0/24
        for_zones:
          - example.com                         # example.com is a zone defined in pillar, see above
```

Note: soa records and zone options can also specified per zone basis but must
be complete because these dicts are not merged, that means then the complete
soa record must be provided.
