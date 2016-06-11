defmodule Rumbl.Repo.Migrations.CreateCategory do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string

      timestamps
    end

    create unique_index(:categories, [:name])

    alter table(:videos) do
      add :category_id, references(:categories)
    end
  end
end
