defmodule RauversionWeb.MyPurchasesLive.Music do
  use RauversionWeb, :live_view

  on_mount RauversionWeb.UserLiveAuth

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page, 1)
      |> assign(:section, "all_music")
      |> assign(:tickets, [])

    {:ok, socket}
  end

  def get_tickets(current_user, section) do
    case section do
      "all_music" ->
        Rauversion.Accounts.get_album_orders(current_user)

      "all_tracks" ->
        Rauversion.Accounts.get_track_orders(current_user)

      "pending_orders" ->
        Rauversion.Accounts.get_pending_album_orders(current_user)
    end
  end

  @impl true
  def handle_event("section-change", %{"section" => section}, socket) do
    {:noreply, assign(socket, :section, section)}
  end

  def render_item(assigns = %{resource: %Rauversion.AlbumPurchaseOrders.AlbumPurchaseOrder{}}) do
    ~H"""
    <div class="flex space-x-2">
      <%= img_tag(
        Rauversion.BlobUtils.blob_representation_proxy_url(
          @resource.playlist,
          "cover",
          %{resize_to_limit: "300x200"}
        ),
        class: "w-20 h-20 object-center object-cover group-hover:opacity-75"
      ) %>

      <div>
        <%= live_redirect to: "/playlists/#{@resource.playlist.slug}" do %>
          <h3 class="text-2xl"><%= @resource.playlist.title %></h3>
        <% end %>

        <span><%= gettext("Created at:") %> <%= @resource.inserted_at %></span>

        <%= if Rauversion.AlbumPurchaseOrders.AlbumPurchaseOrder.is_downloadable?(@resource) do %>
          <p class="truncate text-sm font-medium text-brand-600">
            <a
              href={
                Rauversion.AlbumPurchaseOrders.AlbumPurchaseOrder.url_for_download(
                  @resource,
                  @current_user.id
                )
              }
              class="group block"
              target="_blank"
            >
              <%= gettext("Download link") %>
            </a>
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  def render_item(assigns = %{resource: %Rauversion.TrackPurchaseOrders.TrackPurchaseOrder{}}) do
    ~H"""
    <div class="flex space-x-2">
      <%= img_tag(
        Rauversion.BlobUtils.blob_representation_proxy_url(
          @resource.track,
          "cover",
          %{resize_to_limit: "300x200"}
        ),
        class: "w-20 h-20 object-center object-cover group-hover:opacity-75"
      ) %>

      <div>
        <%= live_redirect to: "/tracks/#{@resource.track.slug}" do %>
          <h3 class="text-2xl"><%= @resource.track.title %></h3>
        <% end %>

        <span><%= gettext("Created at:") %> <%= @resource.inserted_at %></span>

        <%= if Rauversion.TrackPurchaseOrders.TrackPurchaseOrder.is_downloadable?(@resource) do %>
          <p class="truncate text-sm font-medium text-brand-600">
            <a
              href={
                Rauversion.TrackPurchaseOrders.TrackPurchaseOrder.url_for_download(
                  @resource,
                  @current_user.id
                )
              }
              class="group block"
              target="_blank"
            >
              <%= gettext("Download link") %>
            </a>
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="min-h-full">
        <header class="bg-gray-50 dark:bg-gray-900 py-8">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 xl:flex xl:items-center xl:justify-between">
            <div class="min-w-0 flex-1">
              <nav class="flex" aria-label="Breadcrumb">
                <ol role="list" class="flex items-center space-x-4">
                  <li>
                    <div>
                      <%= live_redirect to: "/purchases", class: "text-sm font-medium text-gray-500 dark:text-gray-300 hover:text-gray-700 hover:text-gray-300" do %>
                        <%= gettext("Purchases") %>
                      <% end %>
                    </div>
                  </li>
                  <li>
                    <div class="flex items-center">
                      <svg
                        class="h-5 w-5 flex-shrink-0 text-gray-400"
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        aria-hidden="true"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
                          clip-rule="evenodd"
                        />
                      </svg>
                      <a
                        href="#"
                        class="ml-4 text-sm font-medium text-gray-500 dark:text-gray-300 hover:text-gray-700 hover:text-gray-300"
                      >
                        <%= gettext("Music") %>
                      </a>
                    </div>
                  </li>
                </ol>
              </nav>

              <h1 class="mt-2 text-2xl font-bold leading-7 text-gray-900 dark:text-gray-100 dark:text-gray-100 sm:truncate sm:text-3xl sm:tracking-tight">
                <%= gettext("My Purchased music") %>
              </h1>
            </div>
          </div>
        </header>

        <main class="pt-8 pb-16">
          <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="px-4 sm:px-0">
              <h2 class="text-lg font-medium text-gray-900 dark:text-gray-100">
                <%= gettext("Purchased Music", %{section: @section}) %>
              </h2>

              <div class="sm:block">
                <div class="border-b border-gray-200">
                  <nav class="mt-2 -mb-px flex space-x-8" aria-label="Tabs">
                    <a
                      href="#"
                      phx-click="section-change"
                      phx-value-section="all_music"
                      class="border-transparent text-gray-500 dark:text-gray-200 hover:text-gray-700 hover:text-gray-300 hover:border-gray-200 whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm"
                    >
                      <%= gettext("Purchased albums") %>
                      <!--<span class="bg-gray-100 dark:bg-gray-900 text-gray-900 dark:text-gray-100 text-gray-900 dark:text-gray-100 hidden ml-2 py-0.5 px-2.5 rounded-full text-xs font-medium md:inline-block">2</span>-->
                    </a>
                    <!--<a href="#" phx-click={"section-change"} phx-value-section={"pending_orders"} class="border-transparent text-gray-500 dark:text-gray-200 hover:text-gray-700 hover:text-gray-300 hover:border-gray-200 whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm">
                        <%= gettext("Pending orders") %>
                        <span class="hidden bg-gray-100 dark:bg-gray-900 text-gray-900 dark:text-gray-100 text-gray-900 dark:text-gray-100 hidden ml-2 py-0.5 px-2.5 rounded-full text-xs font-medium md:inline-block">4</span>
                      </a>-->
                    <a
                      href="#"
                      phx-click="section-change"
                      phx-value-section="all_tracks"
                      class="border-transparent text-gray-500 dark:text-gray-200 hover:text-gray-700 hover:text-gray-300 hover:border-gray-200 whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm"
                    >
                      <%= gettext("Purchased individual Tracks") %>
                      <!--<span class="hidden bg-gray-100 dark:bg-gray-900 text-gray-900 dark:text-gray-100 text-gray-900 dark:text-gray-100 hidden ml-2 py-0.5 px-2.5 rounded-full text-xs font-medium md:inline-block">4</span>-->
                    </a>
                  </nav>
                </div>
              </div>
            </div>
            <!-- Stacked list -->
            <ul
              role="list"
              class="mt-5 divide-y divide-gray-200 dark:divide-gray-800 border-t border-gray-200 dark:border-gray-800 sm:mt-0 sm:border-t-0"
            >
              <%= for ticket <- get_tickets(@current_user, @section) do %>
                <li>
                  <div class="flex items-center py-5 px-4 sm:py-6 sm:px-0">
                    <div class="flex min-w-0 flex-1 items-center">
                      <div class="min-w-0 flex-1 px-4 md:grid md:grid-cols-2 md:gap-4">
                        <.render_item resource={ticket} current_user={@current_user} />

                        <div class="hidden md:block">
                          <div>
                            <p class="hidden text-sm text-gray-900 dark:text-gray-100">
                              purchased on: <% # = Cldr.DateTime.to_string!(ticket.inserted_at) %>
                              <!---<time datetime={ticket.inserted_at}>
                                  <%= ticket.inserted_at %>
                                </time>-->
                            </p>

                            <%= if ticket.purchase_order.state == "paid" do %>
                              <p class="mt-2 flex items-center text-sm text-gray-500">
                                <svg
                                  class="mr-1.5 h-5 w-5 flex-shrink-0 text-green-400"
                                  xmlns="http://www.w3.org/2000/svg"
                                  viewBox="0 0 20 20"
                                  fill="currentColor"
                                  aria-hidden="true"
                                >
                                  <path
                                    fill-rule="evenodd"
                                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                                    clip-rule="evenodd"
                                  />
                                </svg>
                                <%= ticket.purchase_order.state %>
                              </p>
                            <% else %>
                              <p class="text-sm text-gray-900 dark:text-gray-100">
                                <%= ticket.purchase_order.state %>
                              </p>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div>
                      <!-- Heroicon name: mini/chevron-right -->
                      <svg
                        class="h-5 w-5 text-gray-400 group-hover:text-gray-700 hover:text-gray-300 dark:text-gray-300 dark:text-gray-700"
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        aria-hidden="true"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </div>
                  </div>
                </li>
              <% end %>
            </ul>
            <!-- Pagination -->
              <!--
              <nav class="flex items-center justify-between border-t border-gray-200 px-4 sm:px-0" aria-label="Pagination">
                <div class="-mt-px flex w-0 flex-1">
                  <a href="#" class="inline-flex items-center border-t-2 border-transparent pt-4 pr-1 text-sm font-medium text-gray-500 hover:border-gray-200 hover:text-gray-700 hover:text-gray-300 dark:text-gray-300">
                    <svg class="mr-3 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fill-rule="evenodd" d="M18 10a.75.75 0 01-.75.75H4.66l2.1 1.95a.75.75 0 11-1.02 1.1l-3.5-3.25a.75.75 0 010-1.1l3.5-3.25a.75.75 0 111.02 1.1l-2.1 1.95h12.59A.75.75 0 0118 10z" clip-rule="evenodd" />
                    </svg>
                    Previous
                  </a>
                </div>
                <div class="hidden md:-mt-px md:flex">
                  <a href="#" class="inline-flex items-center border-t-2 border-transparent px-4 pt-4 text-sm font-medium text-gray-500 hover:border-gray-200 hover:text-gray-700 hover:text-gray-300 dark:text-gray-300">1</a>
                  <a href="#" class="inline-flex items-center border-t-2 border-brand-500 px-4 pt-4 text-sm font-medium text-brand-600" aria-current="page">2</a>
                  <a href="#" class="inline-flex items-center border-t-2 border-transparent px-4 pt-4 text-sm font-medium text-gray-500 hover:border-gray-200 hover:text-gray-700 hover:text-gray-300 dark:text-gray-300">3</a>
                  <a href="#" class="inline-flex items-center border-t-2 border-transparent px-4 pt-4 text-sm font-medium text-gray-500 hover:border-gray-200 hover:text-gray-700 hover:text-gray-300 dark:text-gray-300">4</a>
                  <a href="#" class="inline-flex items-center border-t-2 border-transparent px-4 pt-4 text-sm font-medium text-gray-500 hover:border-gray-200 hover:text-gray-700 hover:text-gray-300 dark:text-gray-300">5</a>
                  <a href="#" class="inline-flex items-center border-t-2 border-transparent px-4 pt-4 text-sm font-medium text-gray-500 hover:border-gray-200 hover:text-gray-700 hover:text-gray-300 dark:text-gray-300">6</a>
                </div>
                <div class="-mt-px flex w-0 flex-1 justify-end">
                  <a href="#" class="inline-flex items-center border-t-2 border-transparent pt-4 pl-1 text-sm font-medium text-gray-500 hover:border-gray-200 hover:text-gray-700 hover:text-gray-300 dark:text-gray-300">
                    Next
                    <svg class="ml-3 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fill-rule="evenodd" d="M2 10a.75.75 0 01.75-.75h12.59l-2.1-1.95a.75.75 0 111.02-1.1l3.5 3.25a.75.75 0 010 1.1l-3.5 3.25a.75.75 0 11-1.02-1.1l2.1-1.95H2.75A.75.75 0 012 10z" clip-rule="evenodd" />
                    </svg>
                  </a>
                </div>
              </nav>
              -->
          </div>
        </main>
      </div>
    </div>
    """
  end
end
