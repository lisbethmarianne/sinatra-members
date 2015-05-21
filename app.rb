class NameValidator
  def initialize(name, names)
    @name = name.to_s
    @names = names
    @messages = []
  end

  def valid?
    validate
    @messages.empty?
  end

  def message
    @messages.first
  end

  private

    def validate
      if @name.empty?
        @messages << "You need to enter a name"
      elsif @names.include?(@name)
        @messages << "#{@name} is already included in our list."
      end
    end
end

class MembersApp < Sinatra::Base
  set :method_override, true

  def read_members
    return [] unless File.exist?("members.txt")
    File.read("members.txt").split("\n")
  end

  def store_member(filename, string)
    File.open(filename, "a+") do |file|
      file.puts(string)
    end
  end

  def update_members(filename, members, old_name, new_name)
    members.map! do |name|
      if name == old_name
        name = new_name
      else
        name
      end
    end
    File.open(filename, "w") do |file|
      file.puts(members)
    end
  end

  def delete_member(filename, members, name)
    members.delete(name)
    File.open(filename, "w") do |file|
      file.puts(members)
    end
  end

  enable :sessions

  get "/members" do 
    @members = read_members
    erb :index
  end

  get "/members/new" do
    @message = session.delete(:message)
    erb :new
  end

  get "/members/:name" do
    @name = params[:name]
    @message = session.delete(:message)  
    erb :show
  end

  post "/members" do
    @name = params[:name]
    @members = read_members
    validator = NameValidator.new(@name, @members)

    if validator.valid?
      store_member("members.txt", @name)
      session[:message] = "Successfully stored the member #{@name}."
      redirect to("/members/#{@name}")
    else
      @message = validator.message
      erb :new
    end
  end

  get "/members/:name/edit" do
    @name = params[:name]
    erb :edit
  end

  put "/members/:name" do
    @name = params[:name]
    @new_name = params[:new_name] 
    @members = read_members
    validator = NameValidator.new(@new_name, @members)

    if validator.valid?
      update_members("members.txt", @members, @name, @new_name)
      session[:message] = "Successfully updated the member #{@new_name}."
      redirect to("/members/#{@new_name}")
    else
      @message = validator.message
      erb :edit
    end
  end

  get "/members/:name/delete" do
    @name = params[:name]
    erb :delete
  end

  delete "/members/:name" do
    @name = params[:name]
    @members = read_members

    delete_member("members.txt", @members, @name)
    redirect :members
  end
end

