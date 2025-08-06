# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ApplicationController
  # Skip CSRF token verification for API requests
  skip_before_action :verify_authenticity_token

  # Set response format to JSON
  before_action :set_default_response_format

  # Handle authentication for API
  before_action :authenticate_api_user!

  protected

  def set_default_response_format
    request.format = :json
  end

  def authenticate_api_user!
    # Extract token from Authorization header
    token = request.headers["Authorization"]&.split(" ")&.last

    if token.present?
      begin
        # Decode JWT token (you'll need to implement this)
        decoded_token = JsonWebToken.decode(token)
        @current_user = User.find(decoded_token[:user_id])
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render_unauthorized
      end
    else
      render_unauthorized
    end
  end

  def current_user
    @current_user
  end

  def render_success(data = {}, message = "Success", status = :ok)
    render json: {
      success: true,
      message: message,
      data: data
    }, status: status
  end

  def render_error(message = "Error occurred", status = :bad_request, errors = nil)
    response = {
      success: false,
      message: message
    }
    response[:errors] = errors if errors.present?

    render json: response, status: status
  end

  def render_unauthorized(message = "Unauthorized")
    render json: {
      success: false,
      message: message
    }, status: :unauthorized
  end

  def render_not_found(message = "Resource not found")
    render json: {
      success: false,
      message: message
    }, status: :not_found
  end
end
