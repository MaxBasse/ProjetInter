using JSON
using DataFrames
donnees = JSON.parsefile("data.json")
questions=donnees["questions"]
collection=donnees["collection"]

# etape 1 : vérifier que pour chaque question du questionnaire,
#il existe au moins une espèce dans "collection"
#ayant une probabilité > 0 pour au moins une des réponses à cette question

function check_integrity_questions_collection(questions, collection)
    # Parcours de toutes les questions du questionnaire
    for q in questions
        question = q["title_q"]
        answers = q["answers"]
        question_valid = false  # elle devient true si au moins une espèce valide cette question

        for ans in answers
            answer = ans["title_a"]

            # On regarde si il y a des espèces ou non qui ont cette caractéristique > 0
            for latin in collection
                for choice in latin["choices"]
                    if choice["id_question"] == question
                        for opt in choice["options"]
                            label = opt[1]        # ex: "Herbacées"
                            score = opt[2]        # ex: 1.0
                            if label == answer && score > 0
                                question_valid = true
                                break
                            end
                        end
                    end
                end
            end
        end

        if !question_valid
            println("La question '$question' ne sert à rien car aucune espèce n'a de caractéristique correspondante à ses réponses.")
            return false
        end
    end

    println("Toutes les questions ont bien des réponses associées à des espèces.")
    return true
end



tree = JSON.parsefile("arbre.json")

function check_tree(node; path=[])
    errors = String[]
    species_found = Set{Int}()
    # verification de non mixité branches especes
    if haskey(node, "species") && haskey(node, "branches")
        push!(errors, "Node $(join(path, '/')) has both 'species' and 'branches'")
    end

    # Si c’est une feuille avec espèces, on l'ajoute à la liste des especes
    if haskey(node, "species")
        for s in node["species"]
            push!(species_found, s)
        end
    end

    # Si c’est un nœud avec des branches
    if haskey(node, "branches")
        branches = node["branches"]
        if isempty(branches)
            push!(errors, "Node $(join(path, '/')) has a 'question' but no branches")
        else
            # appel recursif de la fonction
            for (branch_name, subnode) in pairs(branches)
                sub_species, sub_errors = check_tree(subnode; path=[path... , branch_name])
                union!(species_found, sub_species)
                append!(errors, sub_errors)
            end
        end
    end

    return species_found, errors
end

species_found, errors = check_tree(tree)

println("=== Vérification de l'arbre ===")
println("Espèces trouvées : ", sort(collect(species_found)))
if isempty(errors)
    println("Aucune erreur détectée.")
else
    println("Erreurs détectées :")
    for e in errors
        println(" - ", e)
    end
end


#check_integrity_questions_collection(questions, collection)




#Compter les noeuds et les feuilles de l'arbre obtenu

function compter_noeuds_feuilles(arbre)
    # Si c'est une feuille
    if haskey(arbre, "species")
        return (0, 1)  # (noeuds, feuilles)
    end

    # Sinon c'est un noeud
    nb_noeuds = 1
    nb_feuilles = 0

    for sous_arbre in values(arbre["branches"])
        n, f = compter_noeuds_feuilles(sous_arbre)
        nb_noeuds += n
        nb_feuilles += f
    end

    return (nb_noeuds, nb_feuilles)
end

nb_noeuds, nb_feuilles = compter_noeuds_feuilles(tree)
println("Noeuds: $nb_noeuds, Feuilles: $nb_feuilles")
