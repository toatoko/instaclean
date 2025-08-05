class PostsController < ApplicationController
  before_action :authenticate_user!, except: %i[show]
  before_action :set_post, only: %i[ show edit update destroy toggle_like]

  # GET /posts/1 or /posts/1.json
  def show
    @comments = @post.comments.includes(user: [ :avatar_attachment ]).recent
    @comment = Comment.new if user_signed_in?
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  def create
    @post = Post.new(post_params)
    @post.user_id = current_user.id if user_signed_in?
    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: "Post was successfully updated." }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  def toggle_like
    @like = @post.likes.find_by(user: current_user)
    if @like
      @like.destroy
      @liked = false
    else
      @like = @post.likes.create(user: current_user)
      @liked = true
      # Notifications
      if @post.user != current_user
        LikeNotifier.with(liker: current_user, post: @post).deliver_later(@post.user)
      end
    end
    @post.reload
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.replace("like_button_#{@post.id}",
                               partial: "posts/like_button",
                               locals: { post: @post }),
          turbo_stream.replace("likes_count_#{@post.id}",
                               partial: "posts/likes_count",
                               locals: { post: @post })
        ]
      }
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:image, :description)
    end
end
