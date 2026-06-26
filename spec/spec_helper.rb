require 'rspec'
require 'rack/test'
require 'capybara'
require 'capybara/dsl'
require 'json_matchers/rspec'

ENV['RACK_ENV'] = 'test'

require_relative '../server'

JsonMatchers.schema_root = 'spec/support/schemas'

Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: false)
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # ^ Capybara (system specs only, so the DSL's `all` finder doesn't shadow
  # RSpec's `all` matcher in unit specs)
  config.include Capybara::DSL, type: :system

  config.before(:each, type: :system) do
    Capybara.app = App.new
  end

  config.before(:each, type: :request) do
  end

  config.after(:each, type: :system) { App.reset! }

  # ^ Playwright
  config.before(:each, :js) do
    Capybara.current_driver = :playwright
  end

  # ^ Rspec focus
  config.filter_run_when_matching :focus

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
