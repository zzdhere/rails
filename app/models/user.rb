class User < ActiveRecord::Base
  def self.current=(user)
    @current_user = user
  end

  def self.current
    @current_user
  end

  def self.create_user(account, password, role, is_admin=false)
    count = User.where('account = ?', account).count
    raise Exception.new('Account already exists.') if count > 0

    user = User.new account: account, is_admin: is_admin, role: role
    user.salt = UserHelper::generate_salt
    user.hashed_password = UserHelper::hash_password password, user.salt
    user.save
  end

  def update_password(password)
    self.salt = UserHelper::generate_salt
    self.hashed_password = UserHelper::hash_password password, self.salt
    self.save

    Session.where('user_id=?', self.id).update_all('expired_at = NOW()')
  end
  
end
