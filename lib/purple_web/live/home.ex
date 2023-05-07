defmodule PurpleWeb.HomeLive do
  use PurpleWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:side_nav, if(socket.assigns.current_user, do: [], else: nil))
      |> assign(:page_title, "Home")
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section>
      Purple :)
    </section>
    """
  end
end
