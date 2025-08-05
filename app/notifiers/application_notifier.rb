class ApplicationNotifier < Noticed::Base
  include Rails.application.routes.url_helpers
  deliver_by :database
end
