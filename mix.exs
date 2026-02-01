defmodule Aperture.MixProject do
  use Mix.Project

  def project do
    [
      app: :aperture,
      deps: deps(),
      description:
        "A library for overload protection via adaptive concurrency, which supports multiple algorithms and custom signal definitions.",
      elixir: "~> 1.19",
      licenses: ["MIT"],
      links: %{"github" => "https://github.com/clark-lindsay/aperture"},
      source_url: "https://github.com/clark-lindsay/aperture",
      start_permanent: Mix.env() == :prod,
      version: "0.0.1"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:stream_data, "~> 1.2", only: :test}
    ]
  end
end
