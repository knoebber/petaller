defmodule Petaller.Board.ItemEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_entries" do
    field :content, :string, default: ""
    field :is_collapsed, :boolean, default: false

    belongs_to :item, Petaller.Board.Item

    timestamps()
  end

  def changeset(item_entry, attrs) do
    item_entry
    |> cast(attrs, [:content, :item_id, :is_collapsed])
    |> validate_required([:content, :item_id])
    |> assoc_constraint(:item)
  end
end
