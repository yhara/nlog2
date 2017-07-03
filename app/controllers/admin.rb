class NLog2 < Sinatra::Base
  def authenticate!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    return false unless (@auth.provided? and @auth.basic? and @auth.credentials)
    username, password = *@auth.credentials
    correct_pass = BCrypt::Password.new(NLog2.config[:auth][:password_hash])

    return (username == NLog2.config[:auth][:username]) &&
           correct_pass.is_password?(password)
  end

  before '/_admin/*' do
    authenticate!
  end
end
