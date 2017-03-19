class PersistStatsJob < GiveOneJob.new(:options)
  @priority = 5
  @queue    = 'default'

  def perform
    Stats.persist
  end
end
