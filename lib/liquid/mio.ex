%Liquid.Template{
  blocks: [],
  errors: [],
  presets: %{},
  root: %Liquid.Block{
    blank: false,
    condition: nil,
    elselist: [],
    iterator: [],
    markup: nil,
    name: :document,
    nodelist: [
      %Liquid.Block{
        blank: false,
        condition: %Liquid.Condition{
          child_condition: nil,
          child_operator: nil,
          left: %Liquid.Variable{
            filters: [],
            literal: nil,
            name: "var",
            parts: ["var"]
          },
          operator: :==,
          right: %Liquid.Variable{
            filters: [],
            literal: nil,
            name: "culo",
            parts: ["culo"]
          }
        },
        elselist: [],
        iterator: [],
        markup: "var == culo",
        name: :if,
        nodelist: [" YES "],
        parts: [],
        strict: true
      }
    ],
    parts: [],
    strict: true
  }
}
