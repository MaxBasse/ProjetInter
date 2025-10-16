using JSON
using DataFrames
donnees = JSON.parsefile("data.json")
questions=donnees["questions"]
collection=données["collection"]

# etape 1 : vérifier que pour chaque question du questionnaire,
#il existe au moins une espèce dans "collection"
#ayant une probabilité > 0 pour au moins une des réponses à cette question