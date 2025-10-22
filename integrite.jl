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

function check_integrity_tree(tree)


check_integrity_questions_collection(questions, collection)