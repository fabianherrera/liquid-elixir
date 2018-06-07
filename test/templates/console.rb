# Start REPL with M-x inf-ruby
require 'liquid'

Liquid::Template.error_mode = :strict

data = {
  'companies' => [
    {
      'name' => 'Apple', 'founders' => [
        { 'name' => 'Steve Jobs' },
        { 'name' => 'Steve Wozniak' }
      ]
    },
    {
      'name' => 'Microsoft', 'founders' => [
        { 'name' => 'Bill Gates' },
        { 'name' => 'Paul Allen' }
      ]
    }
  ]
}

data = {
  "var" => {
    "a:b c" => {
      "paged" => "1"
    }
  }
}

template = "{%assign var2 = var['a:b c'].paged %} var2: {{ var2 }}"
template = "{% if product == selected %} Buy {% else %} Fail {% endif %}"
template = "{% assign items = 'potatos,carrots' | split: ',' %}{% for item in items %} {{item}} {% endfor %}"

Liquid::Template.parse(template).render(data)
