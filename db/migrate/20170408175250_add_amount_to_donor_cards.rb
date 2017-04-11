class AddAmountToDonorCards < ActiveRecord::Migration
  def change
    change_table :donor_cards do |t|
      t.decimal "amount", precision: 8, scale: 2, default: 0.0
    end
  end
end
