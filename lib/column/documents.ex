defmodule Column.Documents do
  @moduledoc """
  Document upload and retrieval.

  Upload files (PDF, images, etc.) to Column for attachment to entities,
  evidence submissions, or compliance objects.

  ## Upload a document

      {:ok, doc} = Column.Documents.upload("/tmp/articles_of_incorporation.pdf",
        description: "Articles of Incorporation"
      )

      # Then reference doc["id"] when submitting entity evidence
      Column.Entities.create_evidence("ent_123", %{
        document_id: doc["id"],
        document_type: "articles_of_incorporation"
      })
  """

  alias Column.Client

  @type id :: String.t()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc """
  Upload a document file.

  `file_path` is the local path to the file. Additional metadata
  can be passed as keyword options.
  """
  @spec upload(String.t(), opts()) :: result()
  def upload(file_path, opts \\ []) do
    extra_fields = Keyword.take(opts, [:description, :type])

    parts =
      [{:file, file_path, filename: Path.basename(file_path)}] ++
        Enum.map(extra_fields, fn {k, v} -> {to_string(k), to_string(v)} end)

    Client.post_multipart("/documents", parts, opts)
  end

  @doc "List all uploaded documents."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/documents", Keyword.put(opts, :params, params))
  end

  @doc "Get a document by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/documents/#{id}", opts)
  end
end
