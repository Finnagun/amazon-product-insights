// dProdutos: uma linha por produto (variante), deduplicado pelo maior rating_count.
// Traz o anuncio_id (de MapaAnuncios), preços em dólar (TaxaINRUSD) e a categoria dividida em 5 níveis.
// Esperado: 1.351 linhas.
let
    Origem = Table.ExpandTableColumn(Table.NestedJoin(base_bruta, {"product_id"}, MapaAnuncios, {"product_id"}, "mapa", JoinKind.LeftOuter), "mapa", {"anuncio_id"}, {"anuncio_id"}),

    // 1) Mantém só as colunas do produto (tira reviews e links)
    Colunas = Table.SelectColumns(
        Origem,
        {"product_id", "anuncio_id", "product_name", "category", "discounted_price_rupia", "actual_price_rupia",
         "discount_percentage", "rating", "rating_count", "about_product"}
    ),

    // 2) Ordena pelo maior rating_count e deduplica por product_id
    Ordenado = Table.Buffer(
        Table.Sort(Colunas, {{"rating_count", Order.Descending}})
    ),
    SemDuplicados = Table.Distinct(Ordenado, {"product_id"}),

    // 3) Preços em dólar com a taxa parametrizada
    PrecoDescDolar = Table.AddColumn(SemDuplicados, "discounted_price_dollar", each [discounted_price_rupia] * TaxaINRUSD, type number),
    PrecoCheioDolar = Table.AddColumn(PrecoDescDolar, "actual_price_dollar", each [actual_price_rupia] * TaxaINRUSD, type number),

    // 4) Divide a categoria em níveis (até o nível 5)
    Categorias = Table.SplitColumn(
        PrecoCheioDolar, "category",
        Splitter.SplitTextByDelimiter("|", QuoteStyle.None),
        {"categoria_principal", "categoria_nivel2", "categoria_nivel3", "categoria_nivel4", "categoria_nivel5"}
    ),

    // 5) Tipos finais
    Tipos = Table.TransformColumnTypes(
        Categorias,
        {{"categoria_principal", type text}, {"categoria_nivel2", type text}, {"categoria_nivel3", type text},
         {"categoria_nivel4", type text}, {"categoria_nivel5", type text}},
        "en-US"
    )
in
    Tipos
