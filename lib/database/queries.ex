defmodule Chatger.Database.Queries do
  require Logger
  alias Chatger.Database

  def check_credentials(username, password) do
    # TODO add SHA3 hash, requires recompiling sqlite or extension fuckery
    sql = "SELECT user_id FROM users WHERE username = ? AND password_hash = ?;"
    params = [username, password]

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug("No matching credentials found")
        {:error, :not_found}

      {:ok, [[user_id]]} ->
        Logger.debug("Found matching credentials for user id: #{user_id}")
        {:ok, user_id}

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def update_status(user_id, status) do
    sql = "UPDATE users SET status_id = ? WHERE user_id = ?;"
    params = [status, user_id]

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug("Updated user status")
        :ok

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_channels_list() do
    sql = "SELECT channel_id FROM channels;"
    params = []

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug("No channels found")
        {:error, :not_found}

      {:ok, rows} ->
        channel_ids = Enum.map(rows, fn [id] -> id end)
        Logger.debug("Found #{length(channel_ids)} channels")
        {:ok, channel_ids}

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_user_statuses() do
    sql = "SELECT user_id, status_id FROM users;"
    params = []

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug("No channels found")
        {:error, :not_found}

      {:ok, rows} ->
        id_and_status_pairs = Enum.map(rows, fn [id, status] -> {id, status} end)
        Logger.debug("Found #{inspect(id_and_status_pairs)} user and status pairs")
        {:ok, id_and_status_pairs}

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
