module Log
  module_function

  def log(msg, indent = 3)
    puts "#{'-' * indent}> #{msg}"
  end
end