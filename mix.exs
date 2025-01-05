defmodule StatesLanguage.Mixfile do
  use Mix.Project

  def project do
    [
      app: :states_language,
      version: "0.4.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "StatesLanguage",
      source_url: "https://github.com/entropealabs/states_language",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_apps: [:mix]],
      deps: deps(),
      docs: [
        extra_section: "GUIDES",
        main: "readme",
        extras: ["README.md", "guides/howtos/Map and JSONPath.md"],
        groups_for_extras: ["How-To's": ~r/guides\/howtos\/.?/],
        assets: "assets"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:elixpath, "~> 0.1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18.3", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.4"},
      {:json_xema, "~> 0.6.4"},
      {:telemetry, "~> 1.3"}
    ]
  end

  defp description do
    "Declaratively design state machines that compile to Elixir based :gen_statem processes with the StatesLanguage JSON specification"
  end

  defp package do
    [
      files: ~w(lib priv mix.exs README*),
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/entropealabs/states_language"}
    ]
  end
end
