class AddContextToNonprofits < ActiveRecord::Migration
  def change
    add_column :nonprofits, :context, :string
  end
end
