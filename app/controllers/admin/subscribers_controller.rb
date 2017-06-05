class Admin::SubscribersController < Admin::BaseController
  def index
    @q = Subscriber.includes(:donor).search(params[:q])
    @subscribers = @q.result(distinct: true)
  end

  def show
    @subscriber = Subscriber.find params[:id]
    @donor = @subscriber.donor
  end
end
