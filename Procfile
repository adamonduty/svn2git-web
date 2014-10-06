web: bundle exec rackup -p $PORT
worker: bundle exec sidekiq -c 1 -r ./lib/job_worker.rb
