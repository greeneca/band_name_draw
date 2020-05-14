require_relative 'boot'

require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_model/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'
require 'action_cable/engine'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BandNameDraw
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.cache_store = :memory_store
  end
end
