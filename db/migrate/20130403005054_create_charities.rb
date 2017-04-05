class CreateCharities < ActiveRecord::Migration
  def change
    create_table :charities do |t|
      t.integer :category_id
      t.string :name
      t.text :description
      t.date :featured_on
      t.string :ein
      t.timestamps
    end
  end
end
