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

  def get_channels(channel_ids) do
    placeholders = Enum.map_join(channel_ids, ",", fn _ -> "?" end)
    sql = "SELECT channel_id, channel_name, icon_id FROM channels WHERE channel_id IN (#{placeholders});"
    params = channel_ids

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug("No channels found")
        {:error, :not_found}

      {:ok, rows} ->
        # Default icon_id to 0
        channels = Enum.map(rows, fn [channel_id, name, icon_id] -> {channel_id, name, icon_id || 0} end)
        Logger.debug("Found #{inspect(channels)} channels for ids #{inspect({channel_ids})}")
        {:ok, channels}

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

  def get_users(user_ids) do
    placeholders = Enum.map_join(user_ids, ",", fn _ -> "?" end)
    sql = "SELECT user_id, status_id, username, profile_picture_id, bio FROM users WHERE user_id IN (#{placeholders});"
    params = user_ids

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug("No users found")
        {:error, :not_found}

      {:ok, rows} ->
        # Default pfp_id to 0 and default bio to ""
        channels =
          Enum.map(rows, fn [user_id, status_id, username, pfp_id, bio] ->
            {user_id, status_id, username, pfp_id || 0, bio || ""}
          end)

        Logger.debug("Found #{inspect(channels)} users for ids #{inspect({user_ids})}")
        {:ok, channels}

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_history_by_message_anchor(channel_id, message_id, num_messages_back) do
    sql =
      if num_messages_back < 0 do
        """
        SELECT message_id, sent_at, user_id, channel_id, reply_to, content
        FROM messages
        WHERE channel_id = ?
          AND sent_at > (SELECT sent_at FROM messages WHERE message_id = ?1)
           OR (sent_at = (SELECT sent_at FROM messages WHERE message_id = ?2)
               AND message_id >= ?2)
        ORDER BY sent_at ASC, message_id ASC
        LIMIT ?3";
        """
      else
        # //reorder to output messages sorted by `sent_at` older to newer
        """
        SELECT * FROM(
          SELECT message_id, sent_at, user_id, channel_id, reply_to, content
          FROM messages
          WHERE channel_id = ?1
            AND sent_at < (SELECT sent_at FROM messages WHERE message_id = ?2)
             OR (sent_at = (SELECT sent_at FROM messages WHERE message_id = ?2)
                 AND message_id <= ?2)
          ORDER BY sent_at DESC, message_id DESC
          LIMIT ?3";
        ) ORDER BY sent_at ASC, message_id ASC;"
        """
      end

    params = [channel_id, message_id, abs(num_messages_back)]

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug(
          "No messages found in channel #{channel_id} relative to message id #{message_id}, offset #{num_messages_back} messages"
        )

        {:error, :not_found}

      {:ok, rows} ->
        # The media id's column doesnt exist in the db at this point in time (30/07/25)
        # reply id default is 0
        messages =
          Enum.map(rows, fn [message_id, sent_timestamp, user_id, channel_id, reply_id, message] ->
            {message_id, sent_timestamp, user_id, channel_id, reply_id || 0, message, []}
          end)

        Logger.debug("Found #{inspect(messages)} messages")
        {:ok, messages}

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_history_by_timestamp_anchor(channel_id, timestamp, num_messages_back) do
    sql =
      if num_messages_back < 0 do
        """
          SELECT message_id, sent_at, user_id, channel_id, reply_to, content
          FROM message
          WHERE channel_id = ?
            AND sent_at >= ?
          ORDER BY sent_at ASC, message_id ASC
          LIMIT ?;
        """
      else
        """
          SELECT * FROM(
            SELECT message_id, sent_at, user_id, channel_id, reply_to, content
            FROM messages
            WHERE channel_id = ?
              AND sent_at <= ?
            ORDER BY sent_at DESC, message_id DESC
            LIMIT ?
          ) ORDER BY sent_at ASC, message_id ASC;
        """
      end

    params = [channel_id, timestamp, abs(num_messages_back)]

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug(
          "No messages found in channel #{channel_id} relative to timestamp #{timestamp}, offset #{num_messages_back} messages"
        )

        {:ok, []}

      {:ok, rows} ->
        # The media id's column doesnt exist in the db at this point in time (30/07/25)
        # reply id default is 0
        messages =
          Enum.map(rows, fn [message_id, sent_timestamp, user_id, channel_id, reply_id, message] ->
            {message_id, sent_timestamp, user_id, channel_id, reply_id || 0, message, []}
          end)

        Logger.debug("Found #{inspect(messages)} messages")
        {:ok, messages}

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def save_message(user_id, channel_id, reply_id, media_ids, message_text) do
    sql = "INSERT INTO messages (user_id, channel_id, reply_to, content) VALUES (?,?,?,?) RETURNING message_id"
    params = [user_id, channel_id, reply_id, message_text]

    case Database.query(sql, params) do
      {:ok, []} ->
        Logger.debug(
          "Update for channel id #{channel_id}, reply id #{reply_id}, with media ids #{media_ids} and content #{message_text}"
        )

        {:error, :update_failed}

      {:ok, [[message_id]]} ->
        Logger.debug("Inserted message with returning message id #{message_id}")
        {:ok, message_id}

      {:error, reason} ->
        Logger.error("Query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
