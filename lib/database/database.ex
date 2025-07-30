defmodule Chatger.Database do
  use GenServer
  require Logger
  alias Exqlite.Sqlite3

  def start_link(db_path) do
    GenServer.start_link(__MODULE__, db_path, name: __MODULE__)
  end

  def init(_args) do
    # Returns a connection which will be the state of the database connection
    db_path = Application.fetch_env!(:chatger, :db_path)

    with :ok = ensure_db(db_path) do
      {:ok, conn} = Sqlite3.open(db_path)
      Logger.info("Connected to database at #{db_path}")
      {:ok, conn}
    end
  end

  def ensure_db(db_path) do
    create_sql_path = Application.fetch_env!(:chatger, :db_create_sql)
    populate_sql_path = Application.fetch_env!(:chatger, :db_populate_sql)

    if File.exists?(db_path) do
      Logger.debug("Database already exists at #{db_path}")
      :ok
    else
      with :ok <- create_database(db_path, create_sql_path),
           :ok <- populate_database(db_path, populate_sql_path) do
        :ok
      else
        error ->
          Logger.error("Failed to initialize database: #{inspect(error)}")
          Logger.info("Deleting partially initialized database at #{db_path}")
          File.rm(db_path)
          error
      end
    end
  end

  def create_database(db_path, sql_path) do
    with {:ok, sql} <- File.read(sql_path),
         {:ok, conn} <- Sqlite3.open(db_path),
         :ok <- Sqlite3.execute(conn, sql) do
      Logger.info("Database created successfully at #{db_path}")
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to create database: #{inspect(reason)}")
        {:error, reason}

      other ->
        Logger.error("Unexpected error while creating database: #{inspect(other)}")
        {:error, other}
    end
  end

  def populate_database(db_path, sql_path) do
    with {:ok, sql} <- File.read(sql_path),
         {:ok, conn} <- Sqlite3.open(db_path),
         :ok <- Sqlite3.execute(conn, sql) do
      Logger.info("Database populated successfully")
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed populate database: #{inspect(reason)}")
        {:error, reason}

      other ->
        Logger.error("Unexpected error while populating database: #{inspect(other)}")
        {:error, other}
    end
  end

  def handle_call({:exec, sql, params}, _from, conn) do
    {:ok, statement} = Sqlite3.prepare(conn, sql)
    :ok = Sqlite3.bind(statement, params)
    result = fetch_all(conn, statement)
    Sqlite3.release(conn, statement)
    {:reply, result, conn}
  end

  def fetch_all(conn, stmt, acc \\ []) do
    case Sqlite3.step(conn, stmt) do
      {:row, row} -> fetch_all(conn, stmt, [row | acc])
      :done -> {:ok, Enum.reverse(acc)}
      err -> err
    end
  end

  def query(sql, params \\ []) do
    GenServer.call(__MODULE__, {:exec, sql, params})
  end
end
