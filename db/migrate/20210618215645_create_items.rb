class CreateItems < ActiveRecord::Migration[6.1]
  def change
    create_table :items do |t|
      t.datetime :starting
      t.interval :duration
      t.string :name

      t.timestamps
    end
    add_index :items, :starting
  end
end
