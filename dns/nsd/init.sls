nsd:
  service.running:
    - enable: True
    - reload: True

include:
  - .generate_zones
  - .generate_config
