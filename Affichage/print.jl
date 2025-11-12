using JSON
using Luxor

# --- Load JSON file ---
function load_tree(path::String)
    open(path, "r") do f
        return JSON.parse(f)
    end
end

# --- Collect lines into a buffer instead of just printing ---
function build_tree_lines(node::Dict, name::String="(root)", prefix::String="")
    lines = String[]
    # Compose node label
    line = name
    if haskey(node, "question")
        line *= " [Q$(node["question"])]"
    end
    push!(lines, prefix * line)

    # Add species info
    if haskey(node, "species")
        push!(lines, prefix * "  species: " * string(node["species"]))
    end

    # Recurse through branches
    if haskey(node, "branches")
        branches = collect(keys(node["branches"]))
        for (i, key) in enumerate(branches)
            child = node["branches"][key]
            last = (i == length(branches))
            branch_char = last ? "└── " : "├── "
            next_prefix = prefix * (last ? "    " : "│   ")

            if isa(child, Dict)
                line = string(key)
                if haskey(child, "question")
                    line *= " [Q$(child["question"])]"
                end
                push!(lines, prefix * branch_char * line)

                if haskey(child, "species")
                    push!(lines, next_prefix * "species: " * string(child["species"]))
                end

                if haskey(child, "branches")
                    append!(lines, build_branch_lines(child["branches"], next_prefix))
                end
            else
                push!(lines, prefix * branch_char * string(key))
            end
        end
    end
    return lines
end

function build_branch_lines(branches::Dict, prefix::String)
    lines = String[]
    keys_list = collect(keys(branches))
    for (i, key) in enumerate(keys_list)
        child = branches[key]
        last = (i == length(keys_list))
        branch_char = last ? "└── " : "├── "
        next_prefix = prefix * (last ? "    " : "│   ")

        if isa(child, Dict)
            line = string(key)
            if haskey(child, "question")
                line *= " [Q$(child["question"])]"
            end
            push!(lines, prefix * branch_char * line)
            if haskey(child, "species")
                push!(lines, next_prefix * "species: " * string(child["species"]))
            end
            if haskey(child, "branches")
                append!(lines, build_branch_lines(child["branches"], next_prefix))
            end
        else
            push!(lines, prefix * branch_char * string(key))
        end
    end
    return lines
end

# --- PDF writer using Luxor ---
function save_tree_pdf(lines::Vector{String}, output_path::String)
    w, h = 595, 842  # A4 points
    fontsize = 8
    lineheight = fontsize + 3
    nlines_per_page = Int(floor(h / lineheight)) - 5
    page_count = ceil(Int, length(lines) / nlines_per_page)

    @png begin
        sethue("black")
    end

    @pdf output_path begin
        setfont("Courier", fontsize)
        sethue("black")

        line_index = 1
        for p in 1:page_count
            origin()
            translate(20, h - 40)
            for i in 1:nlines_per_page
                if line_index > length(lines)
                    break
                end
                text(lines[line_index], Point(0, -i * lineheight), halign=:left, valign=:top)
                line_index += 1
            end
            if p < page_count
                newpage()
            end
        end
    end
end

# --- Run ---
tree = load_tree("arbre.json")
println("Tree visualization of arbre.json\n")

lines = build_tree_lines(tree)
foreach(println, lines)

output_pdf = "arbre_visualisation.pdf"
save_tree_pdf(lines, output_pdf)
println("\n✅ Tree written to $(output_pdf)")
