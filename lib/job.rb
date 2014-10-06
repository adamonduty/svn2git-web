require 'securerandom'
require 'redis-objects'
require_relative 'job_worker'

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
  attr_writer :options

  def initialize(id = SecureRandom.uuid)
    @id = id
    @options = {}
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
    @options.delete_if {|key, value| value.nil? || value.strip == '' }

    # required
    attributes['svn_url'] = @options['svn_url']
    attributes['git_url'] = @options['git_url']
    attributes['status']  = 'new'

    # optional
    %w(rootistrunk notrunk nobranches notags nominimizeurl metadata verbose username trunk branches tags revision_start revision_end).each do |attr|
      attributes[attr] = @options[attr] if @options[attr]
    end

    # prepend to jobs list
    self.class.jobs.unshift id

    # start job
    JobWorker.perform_async id
  end
end
