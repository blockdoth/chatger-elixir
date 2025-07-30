defmodule Chatger.Database.Queries do
  require Logger
  alias Chatger.Database

  def check_credentials(username, password) do
    # TODO add SHA3 hash, requires recompiling sqlite or extension fuckery
    sql = "SELECT user_id FROM users WHERE username = ? AND password_hash = ?;"
    params = [username, password]

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.info("No matching credentials found")
        {:error, :not_found}

      {:ok, _results} ->
        Logger.info("Found matching credentials")
        {:ok, :passed_check}

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def update_status(user_id, status) do
    sql = "UPDATE users SET status_id = ? WHERE user_id = ?;"
    params = [user_id, status]

    Database.query(sql, params)
  end
end
