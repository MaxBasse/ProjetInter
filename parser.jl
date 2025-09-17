using JSON

file = JSON.parsefile("truncated_data.json", )
println()
println("Parsed JSON data:")
println(file)
print(file["questions"][1])