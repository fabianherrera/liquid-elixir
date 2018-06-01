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
            name: "culo",
            parts: ["culo"]
          },
          operator: :==,
          right: %Liquid.Variable{
            filters: [],
            literal: nil,
            name: "nalga",
            parts: ["nalga"]
          }
        },
        elselist: [
          %Liquid.Block{
            blank: false,
            condition: %Liquid.Condition{
              child_condition: nil,
              child_operator: nil,
              left: %Liquid.Variable{
                filters: [],
                literal: nil,
                name: "shipping",
                parts: ["shipping"]
              },
              operator: nil,
              right: nil
            },
            elselist: ["ahi else"],
            iterator: [],
            markup: "shipping",
            name: :if,
            nodelist: ["aqui elseif"],
            parts: [],
            strict: true
          }
        ],
        iterator: [],
        markup: "culo == nalga",
        name: :if,
        nodelist: [" you "],
        parts: [],
        strict: true
      }
    ],
    parts: [],
    strict: true
  }
}
