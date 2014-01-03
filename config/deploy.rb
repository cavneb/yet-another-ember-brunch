require 'mina/git'

set :domain, 'sweet-domain.io'
set :deploy_to, '/srv/project_name'
set :repository, 'git@github.com:you/project_name'
set :branch, 'master'
set :user, 'deploy'
set :forward_agent, true

set :shared_paths, ['node_modules']

task :environment do
  queue %{
    echo "-----> Loading environment"
    #{echo_cmd %[source ~/.profile]}
  }
end

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/node_modules"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/node_modules"]
end

def unpushed_commits
  `git log --oneline origin/master..HEAD | wc -l`.to_i
end

def check_for_unpushed_changes
  count = unpushed_commits
  if count > 0
    pluralized = count == 1 ? 'commit' : 'commits'
    print "#{count} unpushed #{pluralized}, continue? (yN) "
    answer = STDIN::gets.strip.downcase
    if answer != 'y'
      puts 'Quitting'
      Process.exit
    end
  end
end

desc "Deploys the latest commit from your git remote to the server."
task :deploy => :environment do
  check_for_unpushed_changes

  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    queue 'echo "-----> Installing npm packages"'
    queue 'npm install'
    # Uncomment if you're using bower
    # queue 'echo "-----> Installing bower components"'
    # queue 'bower install'
    queue 'echo "-----> Building with Tapas and Brunch"'
    queue 'cake build'
    queue 'echo "-----> Deleting files not need for deploy"'
    queue 'ls -1 | grep -v public | xargs rm -rf'
  end
end
