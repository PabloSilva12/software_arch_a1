if [ "${USE_TRAEFIK_ASSETS}" = "true" ]; then
  bundle exec rails s -b '0.0.0.0'
else
  bundle exec rails s -b '0.0.0.0' -e production
fi
