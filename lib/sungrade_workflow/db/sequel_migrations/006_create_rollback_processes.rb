p File.basename(__FILE__)

Sequel.migration do
  change do
    create_table(:rollback_processes) do
      primary_key :id
      String :name
      Integer :position
      String :participant_class
      String :status
      String :cursor
      String :to

      foreign_key :procedure_id, :procedures, null: true, index: true
      foreign_key :root_process_id, :processes, null: false, index: true
    end
  end
end
