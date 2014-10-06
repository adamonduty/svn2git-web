require 'sinatra'
require_relative 'lib/job'

get '/' do
  erb :index
end

post '/jobs' do
  @job = Job.new
  @job.options = params['job']
  @job.save!
  redirect "/jobs/#{@job.id}"
end

get '/jobs' do
  @jobs = Job.all
  erb :jobs_index
end

get '/jobs/:job_id' do
  @job = Job.find params[:job_id]
  erb :jobs_show
end
