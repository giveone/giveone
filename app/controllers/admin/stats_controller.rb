class Admin::StatsController < Admin::BaseController
  before_action :set_query

  def index
    Stats.persist # @TODO: DMITRI remove when ths is cron'd up 
    @stats = Stats.new(@q)
  end

  private

  def set_query
    @q = params.fetch(:q, {}).to_h
  end

end
