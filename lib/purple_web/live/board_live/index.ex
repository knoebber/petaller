defmodule PurpleWeb.BoardLive.Index do
  @moduledoc """
  Index page for board
  """
  alias Purple.Board
  import Purple.Filter
  import PurpleWeb.BoardLive.Helpers
  use PurpleWeb, :live_view

  @behaviour PurpleWeb.FancyLink

  @filter_types %{
    show_done: :boolean
  }

  defp assign_data(socket) do
    assigns = socket.assigns
    user_board = assigns.user_board

    saved_tag_names =
      user_board.tags
      |> Purple.maybe_list()
      |> Enum.map(& &1.name)

    filter =
      make_filter(
        socket.assigns.query_params,
        %{
          show_done: user_board.show_done
        },
        @filter_types
      )

    filter =
      if is_nil(Map.get(filter, :tag)) and length(saved_tag_names) > 0 do
        Map.put(filter, :tag, saved_tag_names)
      else
        filter
      end

    tag_options =
      case saved_tag_names do
        [] -> Purple.Tags.make_tag_choices(:item)
        _ -> []
      end

    socket
    |> assign(:editable_item, nil)
    |> assign(:filter, filter)
    |> assign(:items, Board.list_items(filter))
    |> assign(
      :page_title,
      if(user_board.name == "", do: "Default Board", else: user_board.name)
    )
    |> assign(:tag_options, tag_options)
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "🌻"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"user_board_id" => board_id}) do
    user_board = Board.get_user_board(board_id)

    case user_board do
      nil -> nil
      _ -> user_board.name
    end
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    board_id = Purple.int_from_map(params, "user_board_id")

    user_board =
      if board_id do
        Board.get_user_board(board_id)
      else
        %Board.UserBoard{name: "All Items", show_done: true}
      end

    {
      :noreply,
      socket
      |> assign(:query_params, params)
      |> assign(:user_board, user_board)
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => filter_params}, socket) do
    {
      :noreply,
      push_patch(
        socket,
        to: board_path(socket.assigns.user_board.id, filter_params),
        replace: true
      )
    }
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_pin", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.pin_item!(item, !item.is_pinned)
    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_complete", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    item = Board.set_item_complete!(item, item.completed_at == nil)

    index = Enum.find_index(socket.assigns.items, &(&1.id == item.id))

    {
      :noreply,
      assign(
        socket,
        :items,
        List.replace_at(socket.assigns.items, index, item)
      )
    }
  end

  @impl Phoenix.LiveView
  def handle_event("edit_item", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editable_item, Board.get_item!(id))}
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign_side_nav(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <.modal
      :if={!!@editable_item}
      id="edit-item-modal"
      on_cancel={JS.patch(board_path(@user_board.id, @query_params), replace: true)}
      show
    >
      <:title><%= @page_title %></:title>
      <.live_component
        module={PurpleWeb.BoardLive.UpdateItem}
        id={@editable_item.id}
        item={@editable_item}
        return_to={board_path(@user_board.id, @query_params)}
      />
    </.modal>
    <.filter_form :let={f}>
      <.link navigate={item_create_path(@user_board.id)}>
        <.button type="button">Create</.button>
      </.link>
      <.input
        field={{f, :query}}
        value={Map.get(@filter, :query, "")}
        placeholder="Search..."
        phx-debounce="200"
        class="lg:w-1/4"
      />
      <.input
        :if={length(@tag_options) > 0}
        field={{f, :tag}}
        type="select"
        options={@tag_options}
        value={Map.get(@filter, :tag, "")}
        class="lg:w-1/4"
      />
      <.page_links
        filter={@filter}
        first_page={board_path(first_page(@filter))}
        next_page={board_path(next_page(@filter))}
        num_rows={length(@items)}
      />
    </.filter_form>
    <div class="w-full overflow-auto">
      <.table
        filter={@filter}
        get_route={fn new_filter -> board_path(@user_board.id, new_filter) end}
        rows={@items}
      >
        <:col :let={item} label="Item" order_col="id">
          <.link navigate={~p"/board/item/#{item}"}><%= item.id %></.link>
        </:col>
        <:col :let={item} label="Description" order_col="description">
          <.link navigate={~p"/board/item/#{item}"}><%= item.description %></.link>
        </:col>
        <:col :let={item} label="Priority" order_col="priority">
          <%= item.priority %>
        </:col>
        <:col :let={item} label="Status" order_col="status">
          <%= if item.status == :INFO  do %>
            INFO
          <% else %>
            <input
              type="checkbox"
              checked={item.status == :DONE}
              phx-click="toggle_complete"
              phx-value-id={item.id}
            />
          <% end %>
        </:col>
        <:col :let={item} label="Last Activity" order_col="last_active_at">
          <%= Purple.Date.format(item.last_active_at) %>
        </:col>
        <:col :let={item} label="">
          <.link
            class={if(!item.is_pinned, do: "opacity-30")}
            phx-click="toggle_pin"
            phx-value-id={item.id}
            href="#"
          >
            📌
          </.link>
        </:col>
        <:col :let={item} label="">
          <.link href="#" phx-click="edit_item" phx-value-id={item.id}>✏️</.link>
        </:col>
      </.table>
      <.page_links
        filter={@filter}
        first_page={board_path(@user_board.id, first_page(@filter))}
        next_page={board_path(@user_board.id, next_page(@filter))}
        num_rows={length(@items)}
      />
    </div>
    """
  end
end
