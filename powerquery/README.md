# Consultas do Power Query

Código M de todas as consultas do modelo, na ordem em que dependem umas das outras. Este código foi extraído do dashboard final.

| Ordem | Consulta | Arquivo | Carregada no modelo? |
|---|---|---|---|
| 1 | `CaminhoCSV`, `TaxaINRUSD` | `parametros.pq` | Não (parâmetros) |
| 2 | `base_bruta` | `base_bruta.pq` | Não (só referência) |
| 3 | `MapaAnuncios` | `MapaAnuncios.pq` | Não (agrupa as variantes em anúncios) |
| 4 | `dProdutos` | `dProdutos.pq` | Sim |
| 5 | `dReviewTexto` | `dReviewTexto.pq` | Sim |
| 6 | `fReview` | `fReview.pq` | Sim |
| 7 | `dProduct_link_img` | `dProduct_link_img.pq` | Sim |
| 8 | `dStopwords` | `dStopwords.pq` | Não (só apoio à `dPalavras`) |
| 9 | `dPalavras` | `dPalavras.pq` | Sim |
| 10 | `dTemas` | `dTemas.pq` | Sim |

Como usar: no Power BI, **Transformar dados → Nova fonte → Consulta em branco → Editor Avançado**, cole o conteúdo do arquivo e nomeie a consulta com o nome da tabela acima. Os dois parâmetros são criados em **Gerenciar Parâmetros**.

Antes de atualizar, ajuste o parâmetro `CaminhoCSV` para o local do `amazon.csv` no seu computador.
