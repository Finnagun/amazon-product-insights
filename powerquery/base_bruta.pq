let
    Fonte = Csv.Document(File.Contents("C:data/raw/amazon.csv"),[Delimiter=",", Columns=16, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Cabeçalhos Promovidos" = Table.PromoteHeaders(Fonte, [PromoteAllScalars=true]),
    #"Colunas Numéricas Tratadas" = Table.TransformColumns(
    #"Cabeçalhos Promovidos",
    {
        {"discounted_price", each try Number.FromText(Text.Replace(Text.Replace(_, "₹", ""), ",", ""), "en-US") otherwise null, type number},
        {"actual_price",     each try Number.FromText(Text.Replace(Text.Replace(_, "₹", ""), ",", ""), "en-US") otherwise null, type number},
        {"discount_percentage", each try Number.FromText(Text.Replace(_, "%", ""), "en-US") / 100 otherwise null, type number},
        {"rating",           each try Number.FromText(_, "en-US") otherwise null, type number},
        {"rating_count",     each try Number.FromText(Text.Replace(_, ",", ""), "en-US") otherwise null, type number}
    }
),
    #"Renomeado colunas de rupias" = Table.RenameColumns(
    #"Colunas Numéricas Tratadas",
    {
        {"discounted_price", "discounted_price_rupia"},
        {"actual_price", "actual_price_rupia"}
    }
)
in
    #"Renomeado colunas de rupias"