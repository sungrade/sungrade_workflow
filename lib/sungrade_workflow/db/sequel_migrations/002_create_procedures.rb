p File.basename(__FILE__)

Sequel.migration do
  change do
    create_table(:procedures) do
      primary_key :id
      String :target
      Integer :position
      String :participant_class
      String :status
      String :cursor

      foreign_key :procedure_id, :procedures, null: true, index: true
      foreign_key :process_id, :processes, null: true, index: true
      foreign_key :root_process_id, :processes, null: false, index: true
    end
  end
end
