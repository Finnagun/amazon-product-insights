# Consultas do Power Query

Código M das consultas do modelo, na ordem em que dependem umas das outras.

| Ordem | Consulta | Arquivo | Carregada no modelo? |
|---|---|---|---|
| 1 | `base_bruta` | _colar do .pbix (importação, tipagem, divisão de `category`)_ | Não (só referência) |
| 2 | `dProdutos` | _colar do .pbix (deduplicação por maior `rating_count`, tipos, `nome_curto`)_ | Sim |
| 3 | `dStopwords` | `dStopwords.pq` | Não (só apoio à `dPalavras`) |
| 4 | `dReviewTexto` | `dReviewTexto.pq` | Sim |
| 5 | `fReview` | `fReview.pq` | Sim |
| 6 | `dPalavras` | `dPalavras.pq` | Sim |
| 7 | `dTemas` | `dTemas.pq` | Sim |
| 8 | `dProduct_link_img` | `dProduct_link_img.pq` | Sim |

Como usar: no Power BI, **Transformar dados → Nova fonte → Consulta em branco → Editor Avançado**, cole o conteúdo do arquivo e nomeie a consulta com o nome da tabela acima.

> **Pendência do grupo:** exportar o código de `base_bruta` e `dProdutos` (Editor Avançado) para este diretório, para o repositório ficar reproduzível.
