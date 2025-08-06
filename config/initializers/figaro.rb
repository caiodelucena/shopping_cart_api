# Load environment variables from application.yml
Figaro.application = Figaro::Application.new(
  environment: Rails.env,
  path: Rails.root.join("config", "application.yml")
)
Figaro.load