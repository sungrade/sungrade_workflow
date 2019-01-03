p File.basename(__FILE__)

Sequel.migration do
  change do
    create_table(:concurrences) do
      primary_key :id
      String :target
      Integer :position
      Integer :count
      String :participant_class
      String :status

      foreign_key :concurrence_id, :concurrences, null: true, index: true
      foreign_key :procedure_id, :procedures, null: true, index: true
      foreign_key :process_id, :processes, null: true, index: true
      foreign_key :root_process_id, :processes, null: false, index: true
    end

    alter_table(:procedures) do
      add_foreign_key :concurrence_id, :concurrences, null: true, index: true
    end
  end
end
