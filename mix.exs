defmodule Column.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/iamkanishka/column"

  def project do
    [
      app: :column,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      description: "Production-grade Elixir client for the Column Bank API",
      package: package(),

      # Docs
      name: "Column",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),

      # Dialyzer
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_add_apps: [:mix],
        flags: [:error_handling, :underspecs]
      ],

      # Test coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Column.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # HTTP
      {:req, "~> 0.4"},

      # JSON
      {:jason, "~> 1.4"},

      # Telemetry — used directly by Column.Telemetry, declared explicitly
      # rather than relied upon transitively via :req
      {:telemetry, "~> 1.2"},

      # Test helpers
      {:bypass, "~> 2.1", only: :test},
      {:excoveralls, "~> 0.18", only: :test},

      # Static analysis
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Docs
      {:ex_doc, "~> 0.40.3", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "lint.all": ["credo --strict", "dialyzer"],
      "test.all": ["test", "credo --strict"]
    ]
  end

  defp package do
    [
      name: "column",
      maintainers: ["Kanishka Naik"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Column Docs" => "https://docs.column.com"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      groups_for_modules: [
        Core: [
          Column,
          Column.Client,
          Column.Config,
          Column.Error,
          Column.Pagination,
          Column.RateLimit,
          Column.Telemetry
        ],
        Helpers: [Column.Money, Column.Params, Column.Idempotency],
        "Identity & KYC": [Column.Entities],
        Accounts: [Column.BankAccounts, Column.AccountNumbers, Column.Counterparties],
        "Payments — ACH": [Column.ACH],
        "Payments — Book": [Column.BookTransfers],
        "Payments — Wire": [Column.Wires],
        "Payments — International": [Column.InternationalWires],
        "Payments — Realtime": [Column.RealtimeTransfers],
        "Payments — Checks": [Column.Checks],
        "Payments — Unified": [Column.Transfers],
        Lending: [Column.Loans, Column.Disbursements, Column.LoanPayments],
        Observability: [Column.Events, Column.Webhooks, Column.Reporting],
        Webhooks: [Column.WebhookHandler],
        Developer: [Column.Documents, Column.Simulation]
      ]
    ]
  end
end
