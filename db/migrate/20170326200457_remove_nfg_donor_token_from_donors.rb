class RemoveNfgDonorTokenFromDonors < ActiveRecord::Migration
  def change
    remove_column :donors, :nfg_donor_token, :string
  end
end
