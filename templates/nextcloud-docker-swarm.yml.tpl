version: '3.9'

x-default-opts:
  &default-opts
  logging:
    options:
      max-size: "10m"

networks:
  nextcloud-network:
    driver: overlay

services:
  nextcloud:
    <<: *default-opts
    image: nextcloud:${image_tag}
    volumes:
      - ${data_storage_path}:/var/www/html
    environment:
      POSTGRES_HOST: ${db_host}
      POSTGRES_DB: ${db_name}
      DB_PORT: 5432
      POSTGRES_USER: ${db_username}
      POSTGRES_PASSWORD: ${db_password}
      NEXTCLOUD_ADMIN_USER: ${admin_user}
      NEXTCLOUD_ADMIN_PASSWORD: ${admin_user_password}
      NEXTCLOUD_TRUSTED_DOMAINS: ${trusted_domain}
      TRUSTED_PROXIES: ${trusted_domain}
      OVERWRITECLIURL: ${external_url}
      OVERWRITEPROTOCOL: https
      OVERWRITEHOST: ${trusted_domain}
      REDIS_HOST: ${redis_host}
    networks:
      - nextcloud-network
    ports:
      - "80:80"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 90s
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: '1.55'
          memory: 2G
        reservations:
          cpus: '0.55'
          memory: 512M
