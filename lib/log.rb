module Log
  module_function

  def log(msg, indent = 3)
    puts "- #{Time.now} #{'-' * indent}> #{msg}"
  end
end