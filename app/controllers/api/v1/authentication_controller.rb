class Api::V1::AuthenticationController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [ :login, :register ]

  def login
    # Support both email and username login like your web app
    login_param = params[:email] || params[:login] || params[:username]

    # Use your existing find_for_database_authentication method
    user = User.find_for_database_authentication(login: login_param)

    if user&.valid_password?(params[:password])
      # Check if user is banned using your model method
      if user.banned?
        return render_error("Account is banned", :forbidden)
      end

      token = JsonWebToken.encode(user_id: user.id)

      user_data = {
        id: user.id,
        username: user.username,
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name,
        email: user.email,
        bio: user.bio,
        avatar: user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil,
        created_at: user.created_at
      }

      render_success({
        token: token,
        user: user_data
      }, "Login successful")
    else
      render_error("Invalid credentials", :unauthorized)
    end
  end

  def register
    user = User.new(registration_params)

    if user.save
      token = JsonWebToken.encode(user_id: user.id)

      user_data = {
        id: user.id,
        username: user.username,
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name,
        email: user.email,
        bio: user.bio,
        avatar: nil,
        created_at: user.created_at
      }

      render_success({
        token: token,
        user: user_data
      }, "Registration successful", :created)
    else
      render_error("Registration failed", :unprocessable_entity, user.errors.full_messages)
    end
  end

  def logout
    # For JWT, logout is usually handled client-side by removing the token
    render_success({}, "Logout successful")
  end

  def me
    user_data = {
      id: current_user.id,
      username: current_user.username,
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      full_name: current_user.full_name,
      email: current_user.email,
      bio: current_user.bio,
      avatar: current_user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(current_user.avatar, only_path: false) : nil,
      followers_count: current_user.followers_count,
      following_count: current_user.following_count,
      posts_count: current_user.posts_count,
      created_at: current_user.created_at
    }

    render_success(user_data)
  end

  private

  def registration_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :password, :password_confirmation, :bio, :avatar)
  end
end
