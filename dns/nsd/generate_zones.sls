{% set path = "states/dns" %}
{% from path + "/nsd/templates/map.jinja" import map with context %}
{% from path + "/nsd/templates/reverse_zone.jinja" import generate_reverse %}
{% set zones_directory = salt.pillar.get('nsd:config:zones_directory', map.zones_directory) %}
{% set soa             = salt.pillar.get('nsd:config:soa') %}
{% set exclude_pattern = [] %}

{# make sure the directories for the zone files exist with the proper permissions #}
master zones directory:
  file.directory:
    - name:  {{ zones_directory }}/master
    - user:  root
    - group: {{ salt.pillar.get('nsd:config:root_group', map.root_group) }}
    - mode:  {{ salt.pillar.get('nsd:config:master_dirmode',  map.master_dirmode) }}

slave zones directory:
  file.directory:
    - name:  {{ zones_directory }}/slave
    - user:  root
    - group: {{ salt.pillar.get('nsd:config:group', map.group) }}
    - mode:  {{ salt.pillar.get('nsd:config:slave_dirmode',  map.slave_dirmode) }}

{%   for zone, zone_data in pillar.nsd.get('zones', {})|dictsort -%}
{%     set zonefile     = zones_directory + '/master/' + salt.pillar.get('nsd:zones:' + zone + ':file', zone) %}
{%     set soa          = salt.pillar.get('nsd:zones:' + zone + ':soa', soa) %}
{%     set zone_records = zone_data.get('records', {}) %}
{%     set serial_auto  = soa.serial == 'auto' %}

{%     if  salt.pillar.get('nsd:zones:' + zone + ':generate_reverse') %}
{%       do generate_reverse(
            zone_records,
            salt.pillar.get('nsd:zones:' + zone + ':generate_reverse:net'),
            salt.pillar.get('nsd:zones:' + zone + ':generate_reverse:for_zones'),
            salt.pillar.get('nsd:zones', {})
          ) %}
{%     endif %}

{# generate zones only when we are master #}
{% if grains.id == salt.pillar.get('nsd:config:master:name', '')
   or grains.id == zone_data.get('master', {}).get('name', '') %}

{% do exclude_pattern.append(zone) %}

{%- if serial_auto %}
update serial {{ zone }}:
  module.run:
    - name:      dnsutil.serial
    - update:    True
    - zone:      {{ zone }}
    - prereq:
      - file: {{ zonefile }}
{% endif %}

{{ zonefile }}:
  file.managed:
    - source:    salt://{{ path }}/nsd/templates/zone.jinja
    - user:      root
    - group:     {{ salt.pillar.get('nsd:config:root_group', map.root_group) }}
    - mode:      {{ salt.pillar.get('nsd:config:mode',  map.mode) }}
    - template:  jinja
    - context:
        zone:    {{ zone }}
        soa:     {{ soa | json }}
        serial_auto: {{ serial_auto }}
{% if zone_records != {} %}
        records: {{ zone_records | json }}
{% endif %}
    - show_changes: True
    - backup: False
    - check_cmd: nsd-checkzone {{ zone }}

nsd-control reload {{ zone }}:
  cmd.run:
    - onchanges:
      - file: {{ zonefile }}

{% endif %}
{% endfor %}

{# make sure the directory contains only managed zone files #}

{{ zones_directory }}/master:
  file.directory:
    - clean: True
    - backup: minion
    - exclude_pat: {{ exclude_pattern }}
