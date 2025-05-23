defmodule Rauversion.Tracks do
  @moduledoc """
  The Tracks context.
  """

  import Ecto.Query, warn: false
  alias Rauversion.Repo

  alias Rauversion.Tracks.Track

  @topic inspect(__MODULE__)

  def subscribe do
    Phoenix.PubSub.subscribe(Rauversion.PubSub, @topic)
  end

  def broadcast_change({:ok, result}, event) do
    Phoenix.PubSub.broadcast(Rauversion.PubSub, @topic, {__MODULE__, event, result})
    {:ok, result}
  end

  def broadcast_change({:error, result}, _event) do
    {:error, result}
  end

  def signed_id(track) do
    Phoenix.Token.sign(RauversionWeb.Endpoint, "user auth", track.id, max_age: 315_360_000_000)
  end

  def get_track_query(id) do
    from t in Track, where: t.id == ^id
  end

  def get_by_slug_query(id) do
    from t in Track, where: t.slug == ^id
  end

  def find_by_signed_id!(token) do
    case Phoenix.Token.verify(RauversionWeb.Endpoint, "user auth", token) do
      {:ok, track_id} -> get_track!(track_id)
      _ -> nil
    end
  end

  @doc """
  Returns the list of tracks.

  ## Examples

      iex> list_tracks()
      [%Track{}, ...]

  """

  def list_tracks() do
    from p in Track,
      preload: [
        :mp3_audio_blob,
        :cover_blob,
        :cover_attachment,
        user: :avatar_attachment
      ]
  end

  def list_public_tracks() do
    from p in Track,
      where: p.private == false,
      preload: [
        :mp3_audio_blob,
        :cover_blob,
        :cover_attachment,
        user: :avatar_attachment
      ]
  end

  def query_public_tracks(query) do
    query
    |> where([p], p.private == false)
    |> preload([
      :mp3_audio_blob,
      :cover_blob,
      :cover_attachment,
      user: :avatar_attachment
    ])
  end

  def order_by_likes(query) do
    query |> order_by([p], desc: p.likes_count)
  end

  def latests(query) do
    query |> order_by([p], desc: p.id)
  end

  def limit_records(query, count) do
    query |> limit(^count)
  end

  def with_processed(query) do
    query |> where([t], t.state == "processed")
  end

  def published(query) do
    query |> where([t], t.private == false)
  end

  def order_desc(query) do
    query |> order_by([t], desc: t.id)
  end

  def list_tracks_by_ids(ids) do
    list_public_tracks() |> where([p], p.id in ^ids)
  end

  def list_tracks_by_user_id(user_id) do
    Rauversion.Accounts.get_user!(user_id)
    |> Ecto.assoc(:tracks)
    |> order_desc()
    |> query_public_tracks()
  end

  def list_tracks_by_user_id(user_id, current_user_id) do
    case Rauversion.Accounts.get_user!(user_id) do
      %Rauversion.Accounts.User{} = user ->
        if user.id == current_user_id do
          user
          |> Ecto.assoc(:tracks)
          |> order_desc()
        else
          user
          |> Ecto.assoc(:tracks)
          |> order_desc()
          |> published()
          |> with_processed()
        end

      _ ->
        nil
    end
  end

  def preload_tracks_preloaded_by_user(
        query,
        _current_user_id = %Rauversion.Accounts.User{id: id}
      ) do
    likes_query =
      from pi in Rauversion.TrackLikes.TrackLike,
        where: pi.user_id == ^id

    reposts_query =
      from pi in Rauversion.Reposts.Repost,
        where: pi.user_id == ^id

    query
    |> Ecto.Query.preload([
      :mp3_audio_blob,
      :cover_blob,
      :cover_attachment,
      user: :avatar_attachment,
      likes: ^likes_query,
      reposts: ^reposts_query
    ])
  end

  def preload_tracks_preloaded_by_user(query, _current_user_id = nil) do
    query
    |> Map.put(
      :preload,
      [
        :mp3_audio_blob,
        :cover_blob,
        :cover_attachment,
        user: :avatar_attachment
      ]
    )
  end

  @doc """
  Gets a single track.

  Raises `Ecto.NoResultsError` if the Track does not exist.

  ## Examples

      iex> get_track!(123)
      %Track{}

      iex> get_track!(456)
      ** (Ecto.NoResultsError)

  """
  def get_track!(id), do: Repo.get!(Track, id)
  def get_by_slug!(id), do: Repo.get_by!(Track, slug: id)

  def get_public_track!(id) do
    Track
    |> where(id: ^id)
    |> where([t], is_nil(t.private) or t.private == false)
    |> limit(1)
    |> Repo.one()
  end

  # https://fly.io/phoenix-files/tag-all-the-things/
  def get_tracks_by_tag(tag) do
    from(b in Track, where: ^tag in b.tags, preload: [:user])
  end

  @doc """
  Creates a track.

  ## Examples

      iex> create_track(%{field: value})
      {:ok, %Track{}}

      iex> create_track(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.new_changeset(attrs)
    |> Repo.insert()
    |> broadcast_change([:tracks, :created])
  end

  @doc """
  Updates a track.

  ## Examples

      iex> update_track(track, %{field: new_value})
      {:ok, %Track{}}

      iex> update_track(track, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Track.process_one_upload(attrs, "cover")
    |> Track.process_one_upload(attrs, "audio")
    |> Repo.update()
    |> broadcast_change([:tracks, :updated])
  end

  @doc """
  Deletes a track.

  ## Examples

      iex> delete_track(track)
      {:ok, %Track{}}

      iex> delete_track(track)
      {:error, %Ecto.Changeset{}}

  """
  def delete_track(%Track{} = track) do
    Repo.delete(track)
    |> broadcast_change([:tracks, :destroyed])
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking track changes.

  ## Examples

      iex> change_track(track)
      %Ecto.Changeset{data: %Track{}}

  """
  def change_track(%Track{} = track, attrs \\ %{}) do
    Track.changeset(track, attrs)
  end

  def change_new_track(%Track{} = track, attrs \\ %{}) do
    Track.new_changeset(track, attrs)
  end

  def metadata(track, type) do
    case track do
      %{metadata: nil} ->
        nil

      %{metadata: metadata} ->
        metadata |> Map.get(type)

      _ ->
        nil
    end
  end

  # processes clip only for :local
  def reprocess_peaks(track) do
    # track = Rauversion.Tracks.get_track!(7) |> Rauversion.Repo.preload(:audio_blob)
    # Rauversion.Tracks.get_track!(7) |> Rauversion.Repo.preload(:audio_blob) |> Rauversion.Tracks.reprocess_peaks()

    blob = Rauversion.Tracks.blob_for(track, :mp3_audio)
    # service = blob |> ActiveStorage.Blob.service()

    case ActiveStorage.Blob.download(blob) do
      {:ok, contents} ->
        duration = blob_duration_metadata(blob)
        path = generate_local_copy(contents)
        data = Rauversion.Services.PeaksGenerator.run(path, duration)
        # pass track.metadata.id is needed in order to merge the embedded_schema properly.
        case track.metadata do
          nil ->
            update_track(track, %{metadata: %{peaks: data}})

          metadata ->
            update_track(track, %{metadata: %{id: metadata.id, peaks: data}})
        end

      err ->
        IO.inspect(err)
        IO.puts("can't download the file")
        nil
    end
  end

  def regenerate_mp3(track) do
    blob = Rauversion.Tracks.blob_for(track, :audio)

    case ActiveStorage.Blob.download(blob) do
      {:ok, contents} ->
        file = %{
          path: generate_local_copy(contents),
          filename: blob.filename,
          content_type: blob.content_type
        }

        Rauversion.Tracks.Track.convert_to_mp3(
          Rauversion.Tracks.change_track(track),
          file
        )

      err ->
        IO.inspect(err)
        IO.puts("can't download the file")
        nil
    end
  end

  def is_processed?(track) do
    track.state == "processed"
  end

  def prompt_cover(prompt) do
    client = Rauversion.Services.OpenAi.new()
    Rauversion.Services.OpenAi.images(client, prompt)
  end

  def confirm_prompt(track, url) do
    # TODO:
    %HTTPoison.Response{body: body} = HTTPoison.get!(url)
    tmp_path = "/tmp/image-#{Ecto.UUID.generate()}.png"
    :ok = File.write!(tmp_path, body)

    file = %{
      content_type: "image/png",
      filename: "image",
      path: tmp_path
    }

    Rauversion.BlobUtils.attach_file_with_blob(track, "cover", file)
  end

  def blob_duration_metadata(blob) do
    metadata = ActiveStorage.Blob.metadata(blob)

    case metadata do
      %{"duration" => duration} ->
        duration

      _ ->
        ActiveStorage.Blob.analyze(blob) |> ActiveStorage.Blob.metadata() |> Map.get("duration")
    end
  end

  def generate_local_copy(contents) do
    {:ok, fd, file_path} = Temp.open("my-file")
    IO.puts("GENERATED LOCAL COPY: ")
    IO.puts(file_path)
    IO.binwrite(fd, contents)
    File.close(fd)
    file_path
  end

  ### orders
  def purchases_for_track(track_id) do
    from p in Rauversion.TrackPurchaseOrders.TrackPurchaseOrder,
      join: c in assoc(p, :purchase_order),
      where: p.track_id == ^track_id and c.state == "paid",
      preload: [purchase_order: [user: :avatar_blob]],
      select: %{track_order: p, order: c},
      group_by: [p.id, c.id, c.user_id],
      distinct: c.user_id,
      limit: 20
  end

  defdelegate blob_url(user, kind), to: Rauversion.BlobUtils

  defdelegate blob_for(track, kind), to: Rauversion.BlobUtils

  defdelegate blob_proxy_url(user, kind), to: Rauversion.BlobUtils

  defdelegate variant_url(track, kind, options), to: Rauversion.BlobUtils

  defdelegate blob_url_for(track, kind), to: Rauversion.BlobUtils

  def proxy_cover_representation_url(track, options \\ %{resize_to_fill: "250x250"}) do
    Rauversion.BlobUtils.blob_representation_proxy_url(track, "cover", options)
  end

  def iframe_code_string(url, track) do
    '<iframe width="100%" height="100%" scrolling="no" frameborder="no" allow="autoplay" src="#{url}"></iframe><div style="font-size: 10px; color: #cccccc;line-break: anywhere;word-break: normal;overflow: hidden;white-space: nowrap;text-overflow: ellipsis; font-family: Interstate,Lucida Grande,Lucida Sans Unicode,Lucida Sans,Garuda,Verdana,Tahoma,sans-serif;font-weight: 100;"><a href="#{track.user.username}" title="#{track.user.username}" target="_blank" style="color: #cccccc; text-decoration: none;">#{track.user.username}</a> · <a href="#{url}" title="#{track.title}" target="_blank" style="color: #cccccc; text-decoration: none;">#{track.title}</a></div>'
  end
end
