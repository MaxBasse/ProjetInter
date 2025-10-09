using JSON

data = JSON.parsefile("truncated_data.json")

pair_map = Dict{Tuple{String, String}, Int}()
id_to_pair = Dict{Int, Tuple{String, String}}()

idx = 1

function process_question(q)
    global idx
    qtext = q["title_q"]
    for a in q["answers"]
        atext = a["title_a"]
        pair = (qtext, atext)
        if !haskey(pair_map, pair)
            pair_map[pair] = idx
            id_to_pair[idx] = pair
            idx += 1
        end
        # Récursivité sur les sous-questions
        if haskey(a, "unlock_questions")
            for subq in a["unlock_questions"]
                process_question(subq)
            end
        end
    end
end

for q in data["questions"]
    process_question(q)
end

# Exemple d'utilisation :
for (pair, id) in pair_map
    println(pair[1], " : ", pair[2], " : ", id)
end

# Mapping inverse :
for (id, pair) in id_to_pair
    println(id, " => ", pair[1], " : ", pair[2])
end


println(length(pair_map))