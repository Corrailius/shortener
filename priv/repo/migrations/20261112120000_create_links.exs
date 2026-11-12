defmodule Shortener.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links, primary_key: false) do
      add :code, :text, primary_key: true, null: false
      add :url, :text, null: false
    end
  end
end
