# spec/support/simplecov.rb
# Loaded first in spec_helper.rb via require (before Rails loads)
# so coverage tracking starts from the beginning.
require 'simplecov'

SimpleCov.start 'rails' do
  # Enforce 80% minimum only when explicitly requested (e.g. CI pipeline).
  minimum_coverage 80 if ENV['COVERAGE_ENFORCE'] == 'true'

  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/bin/'
  add_filter '/vendor/'

  add_group 'Models',      'app/models'
  add_group 'Services',    'app/services'
  add_group 'Jobs',        'app/jobs'
  add_group 'Commands',    'app/commands'
  add_group 'Controllers', 'app/controllers'
end
