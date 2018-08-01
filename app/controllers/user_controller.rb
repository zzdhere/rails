class UserController < ApplicationController
  skip_before_filter :user_login_filter, only: [:login]
  def login
    session = UserHelper::login params[:account], params[:password], request.remote_ip
    user = User.find(session.user_id)
    render_success_json({
      status: 'success',
      account: user.account,
      user: session.user_id,
      token: Base64.strict_encode64("#{session.user_id}:#{session.token}"),
      role: Role.find(user.role)
    })
  rescue Exception => e
    render :json => {status: 'failure', errmsg: e.message, data: nil}
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end

  def me
    attrs = User.current.attributes.except("salt", "hashed_password")
    attrs['role'] = Role.find(User.current.role).attributes
    attrs['role']['power'] = ActiveSupport::JSON.decode(attrs['role']['power'])
    attrs['system_config'] = ApplicationHelper::system_configs
    attrs[:docs] = {}
    attrs[:docs][:years] = FmisReport::SapDocument.select("DISTINCT(SUBSTRING_INDEX(month_year, '-', 1)) AS year").collect {|d| d.year}
    attrs[:fx] = {}
    attrs[:fx][:months] = FmisReport::Fx.select("distinct(month_year) as month_year").order('month_year').collect {|f| f.month_year}
    render_success_json attrs
  end
end
