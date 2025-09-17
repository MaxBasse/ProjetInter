using JSON

file = JSON.parsefile("data.json")
println()
println("Parsed JSON data:")
println(file)
print(file["questions"][1]["title_q"])
println()
println(file["questions"][1]["answers"][1]["title_a"])

println(file["questions"][1])
length(file)

for i in (1:length(file))
    print(keys(file))
end

curObj = file
for k in keys(file)
curObj = file[k]
    println(k)

    for k1 in keys(curObj)
        curObj = curObj[k1]
        println(k1)

        for k2 in keys(curObj)
            
            println(curObj)
            curObj = curObj[k2]
            
            
        end
        println("OKAYYY")

    end

    println("OKAYYY")
end