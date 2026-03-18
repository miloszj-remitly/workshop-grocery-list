Configure monitoring for our application. Ready files in task3 direcotry

https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/

  prometheus:
    image: prom/prometheus
    ports:
      - 9090:9090
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml