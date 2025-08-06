# app/controllers/api/v1/authentication_controller.rb
class Api::V1::AuthenticationController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [ :login, :register ]

  def login
    # Support both email and username login like your web app
    login_param = params[:email] || params[:login]

    # Find user by email or username
    user = User.find_by(email: login_param) || User.find_by(username: login_param)

    if user&.valid_password?(params[:password])
      # Check if user is banned
      if user.banned_at.present?
        return render_error("Account is banned", :forbidden)
      end

      token = JsonWebToken.encode(user_id: user.id)

      user_data = {
        id: user.id,
        username: user.username,
        name: user.name,
        email: user.email,
        bio: user.bio,
        avatar: user.avatar.attached? ? user.avatar.url : nil,
        created_at: user.created_at
      }

      render_success({
        token: token,
        user: user_data
      }, "Login successful")
    else
      render_error("Invalid email or password", :unauthorized)
    end
  end

  def register
    user = User.new(registration_params)

    if user.save
      token = JsonWebToken.encode(user_id: user.id)

      user_data = {
        id: user.id,
        username: user.username,
        name: user.name,
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
    # You could implement a blacklist system if needed
    render_success({}, "Logout successful")
  end

  def me
    user_data = {
      id: current_user.id,
      username: current_user.username,
      name: current_user.name,
      email: current_user.email,
      bio: current_user.bio,
      avatar: current_user.avatar.attached? ? current_user.avatar.url : nil,
      followers_count: current_user.followers.count,
      following_count: current_user.following.count,
      posts_count: current_user.posts.where(active: true).count,
      created_at: current_user.created_at
    }

    render_success(user_data)
  end

  private

  def registration_params
    params.require(:user).permit(:name, :username, :email, :password, :password_confirmation, :bio)
  end
end
