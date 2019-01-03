p File.basename(__FILE__)

Sequel.migration do
  change do
    create_table(:processes) do
      primary_key :id
      String :name, null: false
      String :version, null: false
      String :entity_id, null: false
      String :entity_class, null: false
      String :identifier, null: false
      String :participant_class
      String :status
    end
  end
end
