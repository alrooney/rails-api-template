desc "Run the full CI suite: rspec, rubocop, brakeman, bundle audit"
task ci: [ "ci:rspec", "ci:rubocop", "ci:brakeman", "ci:audit" ]

namespace :ci do
  desc "Run RSpec with coverage enforcement"
  task :rspec do
    sh "bundle exec rspec"
  end

  desc "Run Rubocop"
  task :rubocop do
    sh "bundle exec rubocop"
  end

  desc "Run Brakeman security scan"
  task :brakeman do
    sh "bundle exec brakeman -q -w2"
  end

  desc "Run bundle-audit vulnerability check"
  task :audit do
    sh "bundle exec bundle audit check --update"
  end
end
