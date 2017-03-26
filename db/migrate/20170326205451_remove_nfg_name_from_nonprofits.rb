class RemoveNfgNameFromNonprofits < ActiveRecord::Migration
  def change
    remove_column :nonprofits, :nfg_name, :string
  end
end
