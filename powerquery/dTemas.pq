// dTemas: dicionário de palavras-chave por tema. Esperado: 81 linhas (8 temas).
// Cada palavra pode pertencer a UM único tema (relacionamento 1:N com a dPalavras).
let
    Definicao = {
        {"Valor percebido", "Logística", "delivery delivered shipping shipped shipment packaging packing packed package arrived courier parcel"},
        {"Valor percebido", "Preço e desconto", "price priced pricing prices value worth affordable budget cost costly expensive overpriced discount discounted"},
        {"Valor percebido", "Qualidade e desempenho", "quality build durable durability sturdy performance design looks finish premium features"},
        {"Valor percebido", "Atendimento e garantia", "warranty support customer seller installation technician care"},
        {"Problema", "Defeito e falha", "defective defect defects faulty malfunction malfunctioning stopped broke broken damaged dead failed failure"},
        {"Problema", "Devolução e troca", "return returned refund refunded replacement replace replaced exchange"},
        {"Problema", "Falsificado e fraude", "fake duplicate counterfeit fraud cheated scam"},
        {"Problema", "Insatisfação", "poor worst waste useless disappointed disappointing horrible pathetic terrible worthless"}
    },
    Tabela = Table.FromRows(Definicao, {"grupo", "tema", "palavras"}),
    Lista = Table.AddColumn(Tabela, "palavra", each Text.Split([palavras], " ")),
    Expandido = Table.ExpandListColumn(Lista, "palavra"),
    Final = Table.TransformColumnTypes(
        Table.SelectColumns(Expandido, {"grupo", "tema", "palavra"}),
        {{"grupo", type text}, {"tema", type text}, {"palavra", type text}}
    )
in
    Final
