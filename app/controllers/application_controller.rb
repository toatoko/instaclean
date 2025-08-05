class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [ :login ])
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :first_name, :last_name, :email, :avatar ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :avatar, :first_name, :last_name, :username, :email, :bio ])
  end
end
