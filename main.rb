class ValueTable < String
  private
  def tokenize
    tokens = []
    term = self.gsub /\s/, ""
    replacements = { /\-([\d\.x]+\^)/ => '-1*\1', /^\-\(/ => "m1*(",
       /^\-/ => "m", /([+\-\*\/\(])(\-)([\dx])/ => '\1m\3',
       /([+\-\*\/\(])(\-\()/ => '\1m1*(', /([\d\.]+)x/ => '(\1*x)' }
    replacements.each { |pattern, replacement| term.gsub!(pattern, replacement) }
    term.scan(Regexp.union(/m?[\d\.x]+/, /[\(\)+\-\*\/\^]/)).each { |match| tokens << (match.gsub /m/, "-") }
    tokens
  end
  def calculate src
    output = []
    src.each do |item|
      if item.is_a? Numeric
        output << item
      else
        if output.length > 1
          if item == "/" && output[-1] == 0
            output[-2] = 0
          elsif item == "^"
            output[-2] = output[-2].to_f ** output[-1]
          else
            output[-2] = output[-2].to_f.send item, output[-1]
          end
          output.pop
        end
      end
    end
    result = output.empty? ? 0 : output[0]
    result = result.to_i if result.to_i == result.to_f
    result
  end
  def display_table src
	puts (" " * 24) + "x" + (" " * 3) + " | " + (" " * 3) + "f(x)"
    puts (" " * 19) + ("-" * 21)
    src.each do |key, value|
      k = sprintf("%28g", key)
      v = sprintf("%g", value)
      puts k + " | " + v
    end
  end
  public
  def shunting_yard
    def precedence x, y = nil
      collection = {
        "+" => 2,
        "-" => 2,
        "*" => 3,
        "/" => 3,
        "^" => 4
      }
      right_associative = {
        "^" => true
      }
      if !y
        return collection[x]
      end
      if right_associative[x]
        return collection[x] > collection[y]
      end
      collection[x] >= collection[y]
    end
    output = []
    operators = []
    tokens = tokenize
    tokens.each do |token|
      if token == "x"
        output << token
      elsif token == "("
        operators << token
      elsif token == ")"
        until operators.empty? || operators.last == "("
          output << operators.pop
        end
        operators.pop
      elsif precedence token
        while !operators.empty? && precedence(operators.last) && precedence(operators.last, token)
          output << operators.pop
        end
        operators << token
      else
        output << ((token.to_i == token.to_f) ? token.to_i : token.to_f)
      end
    end
    until operators.empty?
      output << operators.pop
    end
    @output = output
    output
  end
  def make_table first = -4, last = 4, step = 0.5
    @output = shunting_yard if !@output
    table = {}
    (first..last).step(step) do |n|
      x = ((n.to_i == n.to_f) ? n.to_i : n)
      src = []
      @output.each do |item|
        src << (item == "x" ? x : item)
      end
      table[x] = calculate src
    end
    display_table table
  end
end


puts ""

term = ""
ARGV.each do |argument|
  term += argument
end

# Example
# term = "4x^3 / (x^2 - 1)"

if term == ""
  term = gets
end

value_table = ValueTable.new term

# puts value_table.shunting_yard.join(" ")
value_table.make_table
# same as
# value_table.make_table -4, 4, 0.5

puts ""
