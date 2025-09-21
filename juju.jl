import(JSON)
using JSON

# Changement de répertoire de travail si nécessaire
# pwd()  # Affiche le répertoire de travail actuel
# cd("C:/Users/justi/Document_Personnel/Scolarite_etudiante/4eme_annee_INSA_Rennes/Semestre_7/Projet interdiciplinaire/Code perso")  # Change le répertoire de travail
# pwd()  # Vérifie le changement de répertoire

# Lecture du fichier JSON: file est un dictionnaire
file = JSON.parsefile("question_reponse.json")

# Création d'une liste vide pour contenir les espèces
liste_espece = []

# test d'accès aux données 
# println(file["collection"][1]["latin"])  # Affiche le nom latin de la première espèce

# Parcours de toutes les espèces du fichier JSON
for ligne in file["collection"]
    # Ajout de l'espèce à la fin de la liste des espèces
    push!(liste_espece, ligne["latin"])
end



