include("data_loading.jl")

function load_dataset_from_json(filepath::String, name::String)
    println("📂 Chargement de $name depuis $filepath...")
    
    # --- VOTRE CODE DE CHARGEMENT ---
    data = JSON.parsefile(filepath) # Supposons que vous chargez un JSON brut ici
    
    # Initialisation des conteneurs
    v_q = Vector{String}()
    v_qc = Vector{Vector{Int}}()
    v_c = Vector{String}()
    v_uq = Vector{Vector{Int}}()
    nb_species = length(data["collection"])
    sp_matrix = Ref(BitMatrix(undef, 0, 0)) # Temporaire pour la construction
    vect_species = Vector{String}(undef, nb_species)
    
    # --- APPEL DE VOTRE FONCTION DE REMPLISSAGE ---
    # Je suppose que fill_variables! existe déjà dans votre code
    fill_variables!(v_q, v_qc, v_c, v_uq, sp_matrix, vect_species, data)
    
    # Finalisation
    final_matrix = sp_matrix[] # On extrait la BitMatrix
    
    # Création de l'objet propre
    dataset = DeterminationData(
        v_q, v_qc, v_c, v_uq, final_matrix, vect_species, nb_species
    )
    
    # Stockage dans le garde-manger global
    DATA_STORE[name] = dataset
    println("✅ Dataset '$name' chargé avec succès ($(dataset.nb_species) espèces).")
end