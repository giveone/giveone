class RemoveNfgCofIdFromDonorCards < ActiveRecord::Migration
  def change
    remove_column :donor_cards, :nfg_cof_id, :string
  end
end
