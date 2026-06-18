defmodule Column.Entities do
  @moduledoc """
  KYC and KYB entity management.

  Entities represent persons or businesses on the Column platform.
  KYC/KYB compliance state gates what operations (transfers, account creation)
  are available.

  ## Person entity lifecycle

      {:ok, person} = Column.Entities.create_person(%{
        first_name: "Ada",
        last_name: "Lovelace",
        email: "ada@example.com",
        phone_number: "+14155551234",
        date_of_birth: "1815-12-10",
        ssn: "123-45-6789",
        address: %{
          line_1: "123 Main St",
          city: "San Francisco",
          state: "CA",
          postal_code: "94102",
          country_code: "US"
        }
      })

  ## Business entity lifecycle

      {:ok, biz} = Column.Entities.create_business(%{
        business_name: "Acme Corp",
        ein: "12-3456789",
        business_type: "corporation",
        phone_number: "+14155559999",
        address: %{...}
      })
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}
  @type list_result :: {:ok, map()} | {:error, Column.Error.t()}

  # ---------------------------------------------------------------------------
  # Persons
  # ---------------------------------------------------------------------------

  @doc "Create a person entity (KYC)."
  @spec create_person(params(), opts()) :: result()
  def create_person(params, opts \\ []) do
    Client.post("/entities/person", params, opts)
  end

  @doc "Update a person entity."
  @spec update_person(id(), params(), opts()) :: result()
  def update_person(id, params, opts \\ []) do
    Client.patch("/entities/person/#{id}", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Businesses
  # ---------------------------------------------------------------------------

  @doc "Create a business entity (KYB)."
  @spec create_business(params(), opts()) :: result()
  def create_business(params, opts \\ []) do
    Client.post("/entities/business", params, opts)
  end

  @doc "Update a business entity."
  @spec update_business(id(), params(), opts()) :: result()
  def update_business(id, params, opts \\ []) do
    Client.patch("/entities/business/#{id}", params, opts)
  end

  # ---------------------------------------------------------------------------
  # General
  # ---------------------------------------------------------------------------

  @doc "List all entities. Supports cursor pagination."
  @spec list(opts()) :: list_result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/entities", Keyword.put(opts, :params, params))
  end

  @doc "Get an entity by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/entities/#{id}", opts)
  end

  @doc "Delete an entity."
  @spec delete(id(), opts()) :: result()
  def delete(id, opts \\ []) do
    Client.delete("/entities/#{id}", opts)
  end

  @doc "Get the KYC/KYB compliance status for an entity."
  @spec get_compliance(id(), opts()) :: result()
  def get_compliance(id, opts \\ []) do
    Client.get("/entities/#{id}/compliance", opts)
  end

  # ---------------------------------------------------------------------------
  # Evidence
  # ---------------------------------------------------------------------------

  @doc "Get evidence submitted for an entity."
  @spec get_evidence(id(), opts()) :: list_result()
  def get_evidence(id, opts \\ []) do
    Client.get("/entities/#{id}/evidence", opts)
  end

  @doc "Submit third-party evidence for an entity (e.g. from a KYC provider)."
  @spec create_evidence(id(), params(), opts()) :: result()
  def create_evidence(id, params, opts \\ []) do
    Client.post("/entities/#{id}/evidence", params, opts)
  end

  @doc """
  Submit evidence with a file upload (multipart/form-data).

  `file_path` is the local path to the document to upload.

      Column.Entities.create_evidence_upload("ent_123",
        file_path: "/tmp/passport.pdf",
        document_type: "passport"
      )
  """
  @spec create_evidence_upload(id(), keyword(), opts()) :: result()
  def create_evidence_upload(id, upload_opts, opts \\ []) do
    file_path = Keyword.fetch!(upload_opts, :file_path)
    extra = Keyword.delete(upload_opts, :file_path)

    parts =
      [{:file, file_path, filename: Path.basename(file_path)}] ++
        Enum.map(extra, fn {k, v} -> {to_string(k), to_string(v)} end)

    Client.post_multipart("/entities/#{id}/evidence/upload", parts, opts)
  end

  # ---------------------------------------------------------------------------
  # Requirements
  # ---------------------------------------------------------------------------

  @doc "Get additional KYC/KYB requirements for an entity."
  @spec get_requirements(id(), opts()) :: result()
  def get_requirements(id, opts \\ []) do
    Client.get("/entities/#{id}/requirements", opts)
  end

  @doc "Submit additional KYC/KYB requirements."
  @spec submit_requirements(id(), params(), opts()) :: result()
  def submit_requirements(id, params, opts \\ []) do
    Client.post("/entities/#{id}/requirements", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Associated persons (beneficial owners)
  # ---------------------------------------------------------------------------

  @doc "List associated persons (beneficial owners) for a business entity."
  @spec list_associated_persons(id(), opts()) :: list_result()
  def list_associated_persons(id, opts \\ []) do
    Client.get("/entities/#{id}/associated-persons", opts)
  end

  @doc "Link an associated person to a business entity."
  @spec link_associated_person(id(), params(), opts()) :: result()
  def link_associated_person(id, params, opts \\ []) do
    Client.post("/entities/#{id}/associated-persons", params, opts)
  end

  @doc "Update associated persons for a business entity."
  @spec update_associated_persons(id(), params(), opts()) :: result()
  def update_associated_persons(id, params, opts \\ []) do
    Client.patch("/entities/#{id}/associated-persons", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Narratives
  # ---------------------------------------------------------------------------

  @doc "Create a compliance narrative for an entity."
  @spec create_narrative(id(), params(), opts()) :: result()
  def create_narrative(id, params, opts \\ []) do
    Client.post("/entities/#{id}/narratives", params, opts)
  end

  @doc "List compliance narratives for an entity."
  @spec list_narratives(id(), opts()) :: list_result()
  def list_narratives(id, opts \\ []) do
    Client.get("/entities/#{id}/narratives", opts)
  end

  @doc "Delete a compliance narrative."
  @spec delete_narrative(id(), String.t(), opts()) :: result()
  def delete_narrative(id, narrative_id, opts \\ []) do
    Client.delete("/entities/#{id}/narratives/#{narrative_id}", opts)
  end
end
