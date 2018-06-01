defmodule Liquid.Combinators.Tags.ForTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "for tag: basic tag structures" do
    tags = [
      "{% for item in array %}{% endfor %}",
      "{%for item in array%}{%endfor%}",
      "{%     for     item    in     array    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_combinator(tag, &Parser.for/1, [
        {
          :for,
          [
            for_collection: [
              variable_name: "item",
              value: {:variable, ["array"]}
            ],
            for_body: []
          ]
        }
      ])
    end)
  end

  test "for tag: else tag structures" do
    tags = [
      "{% for item in array %}{% else %}{% endfor %}",
      "{%for item in array%}{%else%}{%endfor%}",
      "{%     for     item    in     array    %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_combinator(
        tag,
        &Parser.for/1,
        for: [
          for_collection: [
            variable_name: "item",
            value: {:variable, ["array"]}
          ],
          for_body: [],
          else: []
        ]
      )
    end)
  end

  test "for tag: limit parameter" do
    tags = [
      "{% for item in array limit:2 %}{% else %}{% endfor %}",
      "{%for item in array limit:2%}{%else%}{%endfor%}",
      "{%     for     item    in     array  limit:2  %}{%   else    %}{%    endfor    %}",
      "{%     for     item    in     array  limit: 2  %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_combinator(
        tag,
        &Parser.for/1,
        for: [
          for_collection: [
            variable_name: "item",
            value: {:variable, ["array"]},
            limit_param: [2]
          ],
          for_body: [],
          else: []
        ]
      )
    end)
  end

  test "for tag: offset parameter" do
    tags = [
      "{% for item in array offset:2 %}{% else %}{% endfor %}",
      "{%for item in array offset:2%}{%else%}{%endfor%}",
      "{%     for     item    in     array  offset:2  %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_combinator(
        tag,
        &Parser.for/1,
        for: [
          for_collection: [
            variable_name: "item",
            value: {:variable, ["array"]},
            offset_param: [2]
          ],
          for_body: [],
          else: []
        ]
      )
    end)
  end

  test "for tag: reversed parameter" do
    tags = [
      "{% for item in array reversed %}{% else %}{% endfor %}",
      "{%for item in array reversed%}{%else%}{%endfor%}",
      "{%     for     item    in     array  reversed  %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_combinator(
        tag,
        &Parser.for/1,
        for: [
          for_collection: [
            variable_name: "item",
            value: {:variable, ["array"]},
            reversed_param: []
          ],
          for_body: [],
          else: []
        ]
      )
    end)
  end

  test "for tag: range parameter" do
    tags = [
      "{% for i in (1..10) %}{{ i }}{% endfor %}",
      "{%for i in (1..10)%}{{ i }}{% endfor %}",
      "{%     for     i     in     (1..10)      %}{{ i }}{%     endfor     %}"
    ]

    Enum.each(tags, fn tag ->
      test_combinator(
        tag,
        &Parser.for/1,
        for: [
          for_collection: [
            variable_name: "i",
            value: {:range, [start: 1, end: 10]}
          ],
          for_body: [variable: ["i"]]
        ]
      )
    end)
  end

  test "for tag: range with variables" do
    test_combinator(
      "{% for i in (my_var..10) %}{{ i }}{% endfor %}",
      &Parser.for/1,
      for: [
        for_collection: [
          variable_name: "i",
          value: {:range, [start: {:variable, ["my_var"]}, end: 10]}
        ],
        for_body: [variable: ["i"]]
      ]
    )
  end

  test "for tag: break tag" do
    test_combinator(
      "{% for i in (my_var..10) %}{{ i }}{% break %}{% endfor %}",
      &Parser.for/1,
      for: [
        for_collection: [
          variable_name: "i",
          value: {:range, [start: {:variable, ["my_var"]}, end: 10]}
        ],
        for_body: [variable: ["i"], break: []]
      ]
    )
  end

  test "for tag: continue tag" do
    test_combinator(
      "{% for i in (1..my_var) %}{{ i }}{% continue %}{% endfor %}",
      &Parser.for/1,
      for: [
        for_collection: [
          variable_name: "i",
          value: {:range, [start: 1, end: {:variable, ["my_var"]}]}
        ],
        for_body: [variable: ["i"], continue: []]
      ]
    )
  end

  test "for tag: invalid tag structure and variable values" do
    test_combinator_error(
      "{% for i in (my_var..10) %}{{ i }}{% else %}{% else %}{% endfor %}",
      &Parser.for/1
    )

    test_combinator_error(
      "{% for i in (my_var..) %}{{ i }}{% else %}{% endfor %}",
      &Parser.for/1
    )
  end
end
