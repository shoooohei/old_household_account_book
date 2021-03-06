class CreatePartners < ActiveRecord::Migration[5.1]
  def change
    create_table :partners do |t|
      t.references :user, foreign_key: true, index: true, unique: true
      t.references :partner, foreign_key: { to_table: :users }, index: true, unique: true
      t.timestamps
    end
  end
end
