// dProduct_link_img: link da imagem (corrigido) e do produto (sem rastreio), um por product_id.
// Esperado: 1.351 linhas, 3 colunas. Relacionamento 1:1 com a dProdutos.
let
    Origem = base_bruta,
    Colunas = Table.SelectColumns(Origem, {"product_id", "rating_count", "img_link", "product_link"}),

    // Mesma regra de desempate da dProdutos: maior rating_count
    Ordenado = Table.Buffer(Table.Sort(Colunas, {{"rating_count", Order.Descending}})),
    SemDuplicados = Table.Distinct(Ordenado, {"product_id"}),

    // Domínio + /images/I/ + código da imagem + .jpg
    ImgNovo = Table.AddColumn(
        SemDuplicados, "img_link_novo",
        each try
            Text.BeforeDelimiter([img_link], "/images/")
            & "/images/I/"
            & Text.BeforeDelimiter(Text.AfterDelimiter([img_link], "/images/I/"), ".")
            & ".jpg"
        otherwise [img_link],
        type text
    ),

    // Remove o sufixo de rastreio do link do produto
    LinkLimpo = Table.TransformColumns(
        ImgNovo,
        {{"product_link", each Text.Split(_, "/ref="){0}, type text}}
    ),
    Final = Table.SelectColumns(LinkLimpo, {"img_link_novo", "product_id", "product_link"})
in
    Final
