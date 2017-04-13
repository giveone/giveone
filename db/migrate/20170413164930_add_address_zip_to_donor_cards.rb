class AddAddressZipToDonorCards < ActiveRecord::Migration
  def change
    change_table :donor_cards do |t|
      t.string "address_zip"
    end
  end
end
