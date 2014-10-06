require 'securerandom'
require 'redis-objects'

class Job
  include Redis::Objects

  class << self
    def all
      ids = Redis::List.new('jobs').values
      ids.map{|id| Job.new(id) }
    end

    def find(id)
      Job.new(id)
    end

    def jobs
      Redis::List.new('jobs')
    end
  end

  attr_reader :id
  hash_key :attributes
  value :log
  attr_writer :svn_url, :git_url

  def initialize(id = SecureRandom.uuid)
    @id = id
  end

  def svn_url
    attributes['svn_url']
  end

  def git_url
    attributes['git_url']
  end

  def status
    attributes['status']
  end

  def status=(arg)
    attributes['status'] = arg
  end

  def save!
    attributes['svn_url'] = @svn_url
    attributes['git_url'] = @git_url
    attributes['status'] = 'new'
    self.class.jobs.unshift id
  end
end
