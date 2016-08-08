class Controller
  def index
    @models = Model.all
    render_200
  end
end
