defmodule LiveViewScheduler.Repo.Migrations.CreateInterviewTables do
  use Ecto.Migration

  def change do
    create table("interview_stages") do
      add :name, :string
      add :duration, :integer
      timestamps(type: :timestamptz)
    end

    create table("interview_availability") do
      add :interview_stage_id, references("interview_stages")
      add :start_datetime, :timestamptz
      add :end_datetime, :timestamptz
      add :deleted, :boolean, default: false
      timestamps(type: :timestamptz)
    end
  end
end
