require 'redis'
redis = Redis.new(url: ENV['REDIS_URL'])