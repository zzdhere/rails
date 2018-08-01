class ApplicationController < ActionController::Base
  include ApplicationHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  before_filter :user_login_filter
  protect_from_forgery with: :null_session, :if => Proc.new {|c| c.request.format == 'application/json' }
  skip_before_filter :verify_authenticity_token, :if => Proc.new {|c| c.request.format == 'application/json' }

  include ErrorHandler

  def user_login_filter
    if check_user_session
      return true
    else
      render json: {status: 'FAILURE', error: 'NOTLOGIN', system_config: ApplicationHelper::system_configs}
    end
  end

  def require_power(pow, options={})
    role = Role.find(User.current.role).powers
    raise ErrorHelper::ApiError.new 'No Powers.', options unless role[pow.to_s] == 1
  end

end
