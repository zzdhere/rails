class Attach::AttachController < ApplicationController
  skip_before_filter :user_login_filter, :only => ['temporary_file']

  def temporary_file
    file = Files::Temporary.find(params[:id])
    mime = Mime::Type.lookup_by_extension(file.file_name.split('.').last)
    send_data file.file_content, :filename => file.file_name, :type => mime.to_s
  end

end
