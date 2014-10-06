require 'sidekiq'
require 'open3'
require 'tmpdir'
require_relative 'job'

class JobWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  # Signal that command execution failed
  class CommandError < StandardError; end

  def perform(job_id)
    @job = Job.find job_id
    Dir.mktmpdir do |dir|
      @dir = dir

      # clone with svn2git
      cmd = 'svn2git'

      # set options
      cmd += ""

      # clone
      @job.status = 'Running svn2git'
      cmd += " #{@job.svn_url}"
      execute cmd

      # assuming success, add git remote
      @job.status = 'Adding git remote'
      cmd = "git remote add origin #{@job.git_url}"
      execute cmd

      # push to git
      @job.status = 'Pushing branches to git'
      cmd = 'git push --all origin'
      execute cmd

      @job.status = 'Pushing tags to git'
      cmd = 'git push --tags origin'
      execute cmd

      @job.status = 'Complete'
    end
  end

  def execute(cmd)
    @job.log.value ||= ''
    @job.log.value = @job.log.value + "\n# executing cd #{@dir} && #{cmd} 2>&1\n"
    exit_status = nil
    Open3.popen3 "cd #{@dir} && #{cmd} 2>&1" do |stdin, stdout, stderr, wait_thread|
      while !stdout.eof?
        @job.log.value = @job.log.value + stdout.read
      end
      exit_status = wait_thread.value
    end
    if !exit_status.success?
      fail_msg = "### Command failed with exit status #{exit_status.exitstatus}: #{cmd}"
      @job.log.value = @job.log.value + "\n#{fail_msg}\n"
      raise CommandError, fail_msg
    end
  end
end
