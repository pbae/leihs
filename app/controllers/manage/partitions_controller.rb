class Manage::PartitionsController < Manage::ApplicationController

  def index
    @partitions = \
      Partition.with_generals(model_ids: params[:model_ids].map(&:presence).compact,
                              inventory_pool_id: current_inventory_pool.id)
  end

end
