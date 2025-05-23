defmodule RauversionWeb.FollowsLive.UserListComponent do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  # use Phoenix.LiveComponent
  use RauversionWeb, :live_component

  def render(
        %{
          collection: _collection
        } = assigns
      ) do
    ~H"""
    <div class="py-4 mx-4">
      <h2 class="text-3xl font-bold"><%= @kind %></h2>
      <ul role="list" class="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
        <%= for item <- @collection do %>
          <li class="col-span-1 flex flex-col text-center">
            <%= live_redirect to: Routes.profile_index_path(@socket, :index, Map.get(item, @kind).username) do %>
              <div class="flex-1 flex flex-col p-8">
                <%= img_tag(Rauversion.Accounts.avatar_url(Map.get(item, @kind), :medium),
                  class: "w-32 h-32 flex-shrink-0 mx-auto rounded-full"
                ) %>
                <h3 class="mt-6 text-gray-900 dark:text-gray-100 text-sm font-medium">
                  <%= Map.get(item, @kind).username %>
                </h3>
              </div>
            <% end %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
