defmodule Liquid.CustomComplexTest do
  use ExUnit.Case
  alias Liquid.{Template, Block}

  defmodule CityOfBLock do
    def parse(%Block{} = block, %Template{} = context) do
      [body] = block.nodelist
      tag_markup = block.markup
      string_list = String.split(body)

      case tag_markup do
        "USA" -> processor(string_list, block, context)
        "Venezuela" -> processor(string_list, block, context)
        _ -> raise Liquid.SyntaxError, message: "#{tag_markup} is not a registered country"
      end
    end

    def render(output, block, context) do
      tag_markup = block.markup
      [nodelist] = block.nodelist

      case tag_markup do
        "USA" ->
          result = usa_city(nodelist)
          {result ++ output, context}

        "Venezuela" ->
          result = venezuelan_city(nodelist)
          {result ++ output, context}
      end
    end

    defp usa_city(city) do
      if String.capitalize(city) in [
           "Boston",
           "Portland",
           "Miami"
         ] do
        ["This is a USA city"]
      else
        ["This is not USA city"]
      end
    end

    defp venezuelan_city(city) do
      if String.capitalize(city) in [
           "Maracaibo",
           "Lara",
           "Caracas",
           "Falcon"
         ] do
        ["This is a Venezuelan city"]
      else
        ["This is not Venezuelan city"]
      end
    end

    defp processor(value, block, context) do
      if length(value) > 1 do
        raise Liquid.SyntaxError, message: "the city has to be a single word."
      else
        {block, context}
      end
    end
  end

  defmodule ColorBoxBLock do
    def parse(%Block{} = block, %Template{} = context) do
      tag_markup = block.markup

      case tag_markup do
        "Red" -> {block, context}
        "red" -> {block, context}
        _ -> raise Liquid.SyntaxError, message: "#{tag_markup} is not a registered color"
      end
    end

    def render(output, block, context) do
      nodelist = block.nodelist

      var = %Liquid.Template{
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
          nodelist: nodelist
        }
      }

      {:ok, response, context} = Liquid.Template.render(var, context)
      boxed = "<div class=\"redbox\">#{response}</div>"
      {[boxed] ++ output, context}
    end
  end

  setup_all do
    Liquid.Registers.register("CityOf", CityOfBLock, Block)
    Liquid.Registers.register("ColorBox", ColorBoxBLock, Block)
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test "custom tag city of a country" do
    assert_template_result(
      "This is a USA city",
      "{% CityOf USA %}Miami{% endCityOf %}"
    )

    assert_template_result(
      "This is not USA city",
      "{% CityOf USA %}Paris{% endCityOf %}"
    )
  end

  test "custom tag create a  HTML div tag with class redbox" do
    assert_template_result("<div class=\"redbox\">\n\nHEllo\n\n There \n</div>\n", """
    {% ColorBox red %}
    {% capture this-thing %}HEllo{% endcapture %}
    {{ this-thing }}
    {% if false %} this text should not go into the output{% endif %}
    {% if true %} There {% endif %}
    {% endColorBox %}
    """)

    assert_template_result("<div class=\"redbox\">\nThis is not USA city\n</div>\n", """
    {% ColorBox red %}
    {% CityOf USA %}Paris{% endCityOf %}
    {% endColorBox %}
    """)
  end

  defp assert_template_result(expected, markup, assigns \\ %{}) do
    assert_result(expected, markup, assigns)
  end

  defp assert_result(expected, markup, assigns) do
    template = Template.parse(markup)

    with {:ok, result, _} <- Template.render(template, assigns) do
      assert result == expected
    else
      {:error, message, _} ->
        assert message == expected
    end
  end
end
