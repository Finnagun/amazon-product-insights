// dPalavras: tabela de fatos de menções (produto x palavra x quantidade), a partir da dReviewTexto.
// Esperado: cerca de 120 mil linhas, 3 colunas (product_id, palavra, qtd).
let
    Origem = dReviewTexto,
    Texto = Table.AddColumn(
        Origem, "texto",
        each (if [review_title] = null then "" else [review_title]) & " "
           & (if [review_content] = null then "" else [review_content]),
        type text
    ),

    // Pontuação, símbolos e quebras de linha usados para separar as palavras
    Separadores = " ,.;:!?()[]{}""'-_/\|+*&%$@=<>~`^" & "#(2022)#(2019)#(2018)#(201C)#(201D)#(2013)#(2014)#(2026)#(2605)#(cr)#(lf)#(tab)",

    // Separa o texto, mantém só letras a-z (descarta hindi, emoji e números) e palavras com 3+ letras
    Tokens = Table.AddColumn(
        Texto, "palavra",
        each List.Select(
            List.Transform(Text.SplitAny([texto], Separadores), each Text.Select(_, {"a".."z"})),
            each Text.Length(_) >= 3
        ),
        type list
    ),
    Expandido = Table.ExpandListColumn(Table.SelectColumns(Tokens, {"product_id", "palavra"}), "palavra"),
    SemVazios = Table.SelectRows(Expandido, each [palavra] <> null),
    SemStop = Table.RemoveColumns(
        Table.NestedJoin(SemVazios, {"palavra"}, dStopwords, {"palavra"}, "stop", JoinKind.LeftAnti),
        {"stop"}
    ),
    Agrupado = Table.Group(SemStop, {"product_id", "palavra"}, {{"qtd", each Table.RowCount(_), Int64.Type}})
in
    Agrupado
