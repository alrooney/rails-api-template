Rails.application.configure do
  next unless Rails.env.production?

  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.base_controller_class = [ "ActionController::API", "ActionController::Base" ]

  config.lograge.custom_options = lambda do |event|
    {
      time: Time.current,
      request_id: event.payload[:request_id],
      user_id: event.payload[:user_id],
      params: event.payload[:params].except("controller", "action")
    }
  end
end
