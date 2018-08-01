class Session < ActiveRecord::Base
  def self.update_session(user_id)
    session = Session.find_or_initialize_by(user_id: user_id)
    session.token = SecureRandom.uuid # if session.blank?
    session.expired_at = DateTime.now + 7.days
    session.save
    session
  end
end
