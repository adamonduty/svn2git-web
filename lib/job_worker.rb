require 'sidekiq'
require 'shellwords'
require 'open3'
require 'tmpdir'
require 'sidekiq/api'
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

      # set boolean options
      %w(rootistrunk notrunk nobranches notags no-minimize-url metadata verbose).each do |attr|
        if @job.attributes[attr] == 'true'
          cmd += " --#{attr}"
        end
      end

      # set value options
      %w(username trunk branches tags).each do |attr|
        value = @job.attributes[attr]
        if value != nil
          cmd += " --#{attr} #{Shellwords.escape(value)}"
        end
      end

      # set revision start/end
      revision_start = @job.attributes['revision_start']
      revision_end = @job.attributes['revision_end']
      if revision_start && revision_end
        cmd += " --revision #{Shellwords.escape(revision_start)}:#{Shellwords.escape(revision_end)}"
      elsif revision_start
        cmd += " --revision #{Shellwords.escape(revision_start)}"
      end

      # clone
      @job.status = 'Running svn2git'
      cmd += " #{Shellwords.escape(@job.svn_url)}"
      execute cmd

      # assuming success, add git remote
      @job.status = 'Adding git remote'
      cmd = "git remote add origin #{Shellwords.escape(@job.git_url)}"
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
  rescue CommandError => e
    @job.status = 'Failed'
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
