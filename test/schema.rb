ActiveRecord::Schema.define(:version => 0) do
  create_table :foo, :force => true do |t|
    t.column :bar, :string
  end
end