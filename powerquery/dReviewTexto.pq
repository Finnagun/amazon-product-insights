// dReviewTexto: texto das reviews (título e conteúdo) concatenado por produto, em minúsculas.
// Esperado: 1.351 linhas.
let
    Origem = base_bruta,
    Colunas = Table.SelectColumns(Origem, {"product_id", "rating_count", "review_title", "review_content"}),
    Ordenado = Table.Buffer(Table.Sort(Colunas, {{"rating_count", Order.Descending}})),
    SemDuplicados = Table.Distinct(Ordenado, {"product_id"}),
    Final = Table.SelectColumns(SemDuplicados, {"product_id", "review_title", "review_content"}),
    Minusculo = Table.TransformColumns(
        Final,
        {{"review_title", Text.Lower, type text}, {"review_content", Text.Lower, type text}}
    )
in
    Minusculo
