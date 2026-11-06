// MapaAnuncios: agrupa variantes do mesmo anúncio (não carregada no modelo).
// Dois produtos são ligados quando compartilham ao menos um review_id; a ligação é transitiva.
// O menor product_id (ordem alfabética) do grupo vira o anuncio_id.
// Esperado: 1.351 linhas (product_id, anuncio_id) e 1.181 grupos distintos.
let
    Fonte = Table.SelectColumns(base_bruta, {"product_id", "review_id"}),
    Produtos = Table.Buffer(Table.Distinct(Table.SelectColumns(Fonte, {"product_id"}))),
    Listas = Table.TransformColumns(Fonte, {{"review_id", each if _ = null then {} else List.Select(List.Transform(Text.Split(_, ","), Text.Trim), each _ <> ""), type list}}),
    Pares = Table.Distinct(Table.ExpandListColumn(Listas, "review_id")),
    PorReview = Table.Group(Pares, {"review_id"}, {{"ids", each List.Sort(List.Distinct([product_id])), type list}}),
    ComRepresentante = Table.AddColumn(PorReview, "representante", each [ids]{0}, type text),
    ArestasBase = Table.ExpandListColumn(Table.SelectColumns(ComRepresentante, {"ids", "representante"}), "ids"),
    Arestas1 = Table.RenameColumns(ArestasBase, {{"ids", "origem"}, {"representante", "destino"}}),
    Arestas2 = Table.FromColumns({Arestas1[destino], Arestas1[origem]}, {"origem", "destino"}),
    Arestas = Table.Buffer(Table.Distinct(Table.Combine({Arestas1, Arestas2}))),
    Inicial = Table.Buffer(Table.RenameColumns(Table.DuplicateColumn(Produtos, "product_id", "anuncio_id"), {{"product_id", "origem"}})),
    Passo = (Estado as table) as table =>
        let
            Ligacoes = Table.NestedJoin(Arestas, {"origem"}, Estado, {"origem"}, "rotulos", JoinKind.LeftOuter),
            ComRotulo = Table.ExpandTableColumn(Ligacoes, "rotulos", {"anuncio_id"}, {"anuncio_id"}),
            MenorVizinho = Table.Group(ComRotulo, {"destino"}, {{"menor", each List.Min([anuncio_id]), type text}}),
            Juncao = Table.NestedJoin(Estado, {"origem"}, MenorVizinho, {"destino"}, "vizinhos", JoinKind.LeftOuter),
            Expandido = Table.ExpandTableColumn(Juncao, "vizinhos", {"menor"}, {"menor"}),
            Novo = Table.AddColumn(Expandido, "novo", each if [menor] = null then [anuncio_id] else List.Min({[anuncio_id], [menor]}), type text),
            Resultado = Table.Buffer(Table.RenameColumns(Table.SelectColumns(Novo, {"origem", "novo"}), {{"novo", "anuncio_id"}}))
        in Resultado,
    Diferencas = (A as table, B as table) as number =>
        let J = Table.NestedJoin(A, {"origem"}, B, {"origem"}, "b", JoinKind.Inner),
            E = Table.ExpandTableColumn(J, "b", {"anuncio_id"}, {"novo"})
        in Table.RowCount(Table.SelectRows(E, each [anuncio_id] <> [novo])),
    Iteracoes = List.Generate(
        () => [atual = Inicial, mudou = true, n = 0],
        each [mudou] and [n] <= Table.RowCount(Produtos),
        each let proximo = Passo([atual]) in [atual = proximo, mudou = Diferencas([atual], proximo) > 0, n = [n] + 1],
        each [atual]
    ),
    Final = List.Last(Iteracoes),
    Mapa = Table.RenameColumns(Final, {{"origem", "product_id"}})
in Mapa
