class NLog2 < Sinatra::Base
  get '/_config/' do redirect '/_config' end
  get '/_config' do
    authenticate!
    @flash = {}

    slim :config
  end

  post '/_categories/' do
    authenticate!
    @flash = {}

    category = Category.new(name: @params[:name])
    if category.save
      redirect '/_config'
    else
      @flash[:error] = "Failed to save record: #{category.errors.messages.inspect}"
      slim :config
    end
  end

  put '/_categories/:id' do
    authenticate!
    category = Category.find_by!(id: params[:id])
    category.name = params[:name]

    if category.save
      redirect '/_config'
    else
      @flash[:error] = "Failed to save record: #{category.errors.messages.inspect}"
      slim :config
    end
  end

  delete '/_categories/:id' do
    authenticate!
    category = Category.find_by!(id: params[:id])
    category.destroy

    redirect '/_config'
  end
end
