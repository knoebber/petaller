defmodule PurpleWeb.FinanceLive.MerchantIndex do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias Purple.Finance.Merchant

  def handle_info({:saved_merchant, id}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Merchant saved")
      |> assign(:merchants, Finance.list_merchants())
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Merchants")
      |> assign(:merchants, Finance.list_merchants())
      |> assign(:side_nav, side_nav())
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <div class="mb-2 sm:w-1/3">
      <.live_component
        action={:new_merchant}
        id={:new}
        module={PurpleWeb.FinanceLive.MerchantForm}
        merchant={%Merchant{}}
      />

    </div>
    <.table rows={@merchants}>
      <:col let={merchant} label="Name">
        <%= merchant.name %>
      </:col>
      <:col let={merchant} label="Description">
        <%= merchant.description %>
      </:col>
    </.table>
    """
  end
end
