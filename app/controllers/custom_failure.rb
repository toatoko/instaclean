class CustomFailure < Devise::FailureApp
  def recall
    if warden_options[:attempted_path]
      redirect_to new_user_session_path, alert: "Your account has been banned."
    else
      super
    end
  end
end
