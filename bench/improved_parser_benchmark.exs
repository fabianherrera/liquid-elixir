Liquid.start()

capture = "Who? {% capture about_me %} I am {{ age }} and my favorite food is {% capture other_variable %}Food{% endcapture %} {{ favorite_food }}{% endcapture %} What?"

templates = [capture]

# time = DateTime.to_string(DateTime.utc_now())

for template <- templates do
  Benchee.run(
    %{
      nimble: fn -> Liquid.NimbleParser.parse(template) end,
      valim: fn -> Liquid.ValimParser.parse(template) end
    },
    warmup: 5,
    time: 20,
    # formatters: [
    #   Benchee.Formatters.Console,
    #   Benchee.Formatters.CSV
    # ],
    # formatter_options: [csv: [file: "bench/results/parser-benchmarks-#{time}.csv"]]
  )
end