class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string  :route, :null => false
      t.boolean :value, :null => false
      t.references :permittable,  :polymorphic => true, :null => false
      t.references :permitted, :polymorphic => true
      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end
