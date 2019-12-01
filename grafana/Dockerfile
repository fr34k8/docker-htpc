FROM grafana/grafana:latest

USER nobody

# disable x-frame-options: deny, so that we can be used with organizr
ENV GF_SECURITY_ALLOW_EMBEDDING=true
