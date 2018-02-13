class NLog2 < Sinatra::Base
  get '/_admin/config/' do redirect '/_admin/config' end
  get '/_admin/config' do
    @flash = {}

    slim :'admin/config'
  end

  post '/_admin/categories/' do
    @flash = {}

    category = Category.new(name: @params[:name])
    if category.save
      redirect '/_admin/config'
    else
      @flash[:error] = "Failed to save record: #{category.errors.messages.inspect}"
      slim :'admin/config'
    end
  end

  put '/_admin/categories/:id' do
    category = Category.find_by!(id: params[:id])
    category.name = params[:name]

    if category.save
      redirect '/_admin/config'
    else
      @flash[:error] = "Failed to save record: #{category.errors.messages.inspect}"
      slim :'admin/config'
    end
  end

  delete '/_admin/categories/:id' do
    category = Category.find_by!(id: params[:id])
    category.destroy

    redirect '/_admin/config'
  end
end
