svn2git-web
===========

_svn2git-web_ is a very basic web interface to _svn2git_: https://github.com/nirvdrum/svn2git

By far the biggest issue convincing others to use _svn2git_ is that they don't have a ruby environment. This removes that problem.

Requirements
------------

In order to run _svn2git-web_, one needs:

* A working ruby environment. Ideally ruby 2.1.2 or later.
* Redis
* A subversion URL (e.g. https://example.com/svn/myproj)
* An initialized, remote git repository (e.g. on github, bitbucket, gitlab, or your server)
* Any necessary SSH keys to checkout your subversion project and push to git.

Installation
------------

Just clone the source and run

```
bundle install
```

Then run the web process:

```
bundle exec rackup -p 4567
```

and the background worker:

```
bundle exec sidekiq -c 1 -r ./lib/job_worker.rb
```
