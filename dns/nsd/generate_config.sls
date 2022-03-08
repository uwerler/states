{% if grains.id == salt.pillar.get('nsd:config:master:name', '') %}
  {% set config  = salt.pillar.get('nsd:config:master:config', {}) %}
  {% set role    = "master" %}
  {% set options = salt.pillar.get('nsd:config:master:options', {}) %}
{% elif grains.id in salt.pillar.get('nsd:config:slaves:names', {}) %}
  {% set config  = salt.pillar.get('nsd:config:slaves:config',
                   salt.pillar.get('nsd:config:master:config', {})) %}
  {% set role    = "slave" %}
  {% set options = salt.pillar.get('nsd:config:slaves:options', {}) %}
{% endif %}

{% if role is defined %}

{% set path = "states/dns" %}
{% from path + "/nsd/templates/map.jinja" import map with context %}

{% set config_dir  = salt.pillar.get('nsd:config:config_dir', map.config_dir) %}
{% set config_file = salt.pillar.get('nsd:config:config_file', map.config_file) %}
{% set zones       = salt.pillar.get('nsd:zones', {})|dictsort(reverse=True) %}

{{ config_file }}:
  file.managed:
    - source: salt://{{ path }}/nsd/templates/config.jinja
    - template: jinja
    - user:  root
    - group: {{ salt.pillar.get('nsd:config:root_group', map.root_group) }}
    - mode:  {{ salt.pillar.get('nsd:config:mode', map.mode) }}
    - context:
        keys:    {{ salt.pillar.get('nsd:config:keys', {}) }}
        config:  {{ config|tojson }}
        zones:   {{ zones|tojson }}
        role:    {{ role }}
        options: {{ options|tojson }}
    - show_changes: True
    - backup: False
    - check_cmd: nsd-checkconf

nsd-control reconfig:
  cmd.run:
    - onchanges:
      - file: {{ config_file }}

{% endif %}
