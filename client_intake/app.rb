enable :sessions
set :session_secret, 'alkjas&&*&^SUPERSECRET'

def client
  client_id = "HE5vOnQWq2qRjnWulTVe0n0Y9AzVqtLIRyCuX936"
  client_secret = "b7fCvyma2MONRj8nl6EiDdBhWs1wOrSWc3PZgqW3"
  access_token = session[:access_token]

  @client ||= ClioClient::Session.new({client_id: client_id, client_secret: client_secret})
  if access_token
    @client.access_token = access_token
  end
  
  return @client
end

def redirect_uri
  uri = URI.parse(request.url)
  uri.path = '/auth/callback'
  uri.query = nil
  uri.to_s
end

get "/auth/new" do
  redirect client.authorize_url(redirect_uri)
end

get '/auth/callback' do
  token = client.authorize_with_code redirect_uri, params[:code]
  if client.authorized?
    session[:access_token] = token["access_token"]
    ap token
    @message = "Successfully authenticated with the server"
    erb :success
  else
    halt 401, "Not authorized\n"
  end
end

get '/who_am_i' do
  user = client.users.who_am_i[1]
  @message = "#{user.first_name} #{user.last_name}"
  erb :who_am_i
end

get '/new' do
  erb :new
end

post '/create' do
  person = client.contacts.new(
    "type" => "Person",
    "first_name" => params["contact"]["first_name"],
    "last_name" => params["contact"]["last_name"],
    "phone_numbers" => [{"name" => "Work", "number" => params["contact"]["phone"]}],
    "email_addresses" => [{"name" => "Work", "address" => params["contact"]["email"]}]
  )
  matter = client.matters.new(
    "status" => "Pending",
    "pending_date" => Date.today,
    "description" => params["matter"]["description"]
  )
  begin
    person.save
    matter.client_id = person.id
    matter.save
    erb :created
  rescue
    @error = "Unable to create new contact"
    erb :new
  end
end