// fReview: uma linha por review (produto, review, usuário). Parte da base_bruta ANTES da deduplicação
// para não perder reviews de produtos repetidos. Esperado: 10.605 linhas, 3 colunas.
let
    Origem = base_bruta,
    Colunas = Table.SelectColumns(Origem, {"product_id", "review_id", "user_id"}),

    // Junta review_id e user_id por posição. Separar os dois pela interface
    // geraria um produto cartesiano (8 x 8 linhas por produto).
    Pares = Table.AddColumn(
        Colunas, "par",
        each List.Zip({
            List.Transform(Text.Split([review_id], ","), Text.Trim),
            List.Transform(Text.Split([user_id], ","), Text.Trim)
        }),
        type list
    ),
    Expandido = Table.ExpandListColumn(Table.SelectColumns(Pares, {"product_id", "par"}), "par"),
    ReviewId = Table.AddColumn(Expandido, "review_id", each [par]{0}, type text),
    UserId = Table.AddColumn(ReviewId, "user_id", each [par]{1}, type text),
    Final = Table.SelectColumns(UserId, {"product_id", "review_id", "user_id"}),
    SemDuplicados = Table.Distinct(Final)
in
    SemDuplicados
