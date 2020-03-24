class Log
  def log(msg, indent = 3)
    puts "#{'-' * indent}> #{msg}"
  end
end