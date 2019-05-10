p File.basename(__FILE__)

Sequel.migration do
  change do
    create_table(:tasks) do
      primary_key :id
      String :name
      Integer :position
      String :participant_class
      String :status
      String :cursor

      foreign_key :procedure_id, :procedures, null: true, index: true
      foreign_key :root_process_id, :processes, null: false, index: true
    end
  end
end
