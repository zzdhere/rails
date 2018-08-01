module UserHelper
  def self.login(account, password, remote_ip)
    raise Exception.new('Account or password not provied.') if account.blank? or password.blank?
    user = User.where('account=?', account).take
    raise Exception.new('Account doesnot exists.') if user.nil?
    
    hashed_password = hash_password password, user.salt
    raise Exception.new('Wrong password.') unless hashed_password.eql? user.hashed_password

    Session.transaction do
      LoginLog.create account: account, remote_ip: remote_ip
      Session.update_session(user.id)
    end
  end

  def self.generate_salt
    SecureRandom.base64(16)
  end

  private
  def self.hash_password(pass, salt)
    digest = Digest::SHA256.new
    digest.reset
    digest.update(Base64.decode64(salt))

    hashed = digest.update(pass).digest

    for i in 1..1023
      digest.reset
      digest.update(hashed)
      hashed = digest.digest
    end

    Base64.strict_encode64(hashed).strip
  end

  def self.bytes_equal?(a, b)
    ret = a.size == b.size
    a.each_with_index {|aa, i| ret &= aa == b[i]}
    ret
  end
end
