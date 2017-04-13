class AddNonProfitIdToDonorCards < ActiveRecord::Migration
  def change
    add_column :donor_cards, :nonprofit_id, :integer
  end
end
