json.array! @query.result do |entry|
  json.timestamp entry.timestamp.strftime("%Y-%m-%d %H:%M:%S.%N")
  json.extract! entry, *LogsTables::KUBERNETES_ATTRIBUTES.keys, :labels, :strings, :numbers, :booleans, :nulls
end
