class RemoveNfgChargeIdFromDonations < ActiveRecord::Migration
  def change
    remove_column :donations, :nfg_charge_id, :string
  end
end
