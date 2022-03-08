{#

Because of multi master check if current master is cluster leader for the
consul cluster and set the local master to reactor leader to avoid that
multiple masters react to the same events.

Run this runner via a schedule on all salt masters.

#}


{% set leader    = salt.consul.status_leader('http://127.0.0.1:8500') %}

{% if leader.data.error is defined %}
  {% set arg = False %}
{% else %}
  {% set leader_ip = leader.data | regex_replace(':.*', '', ignorecase=True) %}
    {% if leader_ip is in grains.ipv4 %}
      {% set arg = True %}
    {% else %}
      {% set arg = False %}
    {% endif %}
{% endif %}

{% if salt.saltutil.runner('reactor.is_leader') != arg %}

reactor.set_leader:
  salt.runner:
    - arg:
      - {{ arg }}

{% endif %}
