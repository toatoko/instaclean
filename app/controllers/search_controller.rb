class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    @users = User.all_except(current_user).includes(:avatar_attachment).where(
      "username ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q",
      q: "%#{@query}%"
    )

    @posts = Post
            .includes(:image_attachment, :user)
            .joins(:user)
            .where(
              "posts.description ILIKE :q OR users.username ILIKE :q OR users.first_name ILIKE :q OR users.last_name ILIKE :q",
              q: "%#{@query}%"
            )
  end
end
