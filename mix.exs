defmodule Bourne.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.trim_trailing
  @source "https://github.com/mtwilliams/bourne"

  def project do [
    app: :bourne,
    elixir: "~> 1.4",
    elixirc_paths: elixirc_paths(Mix.env),
    config_path: "config/config.exs",
    build_path: "_build",
    deps_path: "_deps",
    build_embedded: Mix.env() == :prod,
    start_permanent: Mix.env() == :prod,
    deps: deps(),
    package: package(),
    name: "Bourne for Ecto",
    description: "Better streaming for Ecto.",
    version: @version,
    docs: docs(),
    homepage_url: @source,
    source_url: @source,
    test_coverage: [tool: ExCoveralls]
  ] end

  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: [:postgrex, :ecto, :logger]
  defp applications(_), do: [:ecto, :logger]

  defp deps do [
    {:ecto, "~> 2.1"},

    # Testing
    {:postgrex, "~> 0.13", only: [:test]},
    {:gen_stage, "~> 0.11", only: [:test]},

    {:excoveralls, ">= 0.9.1", only: [:test]},
    {:inch_ex, ">= 0.0.0", only: [:dev, :docs]},

    # Documentation
    {:ex_doc, "~> 0.15", only: [:dev, :docs]},
    {:earmark, "~> 1.1", only: [:dev, :docs]}
  ] end

  defp elixirc_paths(_), do: ~W{lib}

  defp package do [
    maintainers: ["Michael Williams"],
    licenses: ["Public Domain"],
    links: %{"Github" => @source},
    files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md VERSION)
  ] end

  defp docs do [
    main: "Bourne",
    canonical: "http://hexdocs.pm/bourne",
    source_ref: "v#{@version}",
    source_url: @source,
    extras: ~W{README.md CHANGELOG.md}
  ] end
end
