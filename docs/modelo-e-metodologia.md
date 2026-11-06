# Modelo de dados e metodologia de análise

## 1. Modelo de dados

![Modelo de dados](img/modelo-de-dados.png)

O modelo segue as boas práticas de modelagem dimensional do Power BI: dimensões ligadas às tabelas de fatos por relacionamentos um para muitos, com filtro da dimensão para a fato, em torno da dimensão compartilhada `dProdutos`. Como há duas tabelas de fatos (`fReview` e `dPalavras`) que compartilham essa dimensão, o desenho é uma **constelação de fatos**, e não uma estrela pura.

| Tabela | Uma linha representa | Linhas |
|---|---|---|
| `dProdutos` | um produto (cada variante é um produto); a coluna `anuncio_id` agrupa as variantes de um mesmo anúncio | 1.351 |
| `fReview` | uma review de um produto (só chaves) | 10.605 |
| `dReviewTexto` | o texto concatenado das reviews de um produto | 1.351 |
| `dProduct_link_img` | os links (imagem e produto) de um produto | 1.351 |
| `dPalavras` | uma palavra em um produto (com a quantidade de menções) | ~120 mil |
| `dTemas` | uma palavra-chave de um tema | 81 |
| `Medidas` | tabela de apoio que guarda as medidas, em pastas de exibição | n/a |

Consultas de apoio, não carregadas no modelo: `base_bruta` (leitura do CSV), `MapaAnuncios` (agrupamento de variantes) e `dStopwords` (159 palavras ignoradas na análise de texto). Os parâmetros são `CaminhoCSV` e `TaxaINRUSD`.

**Relacionamentos:**

- `fReview` → `dProdutos` (`product_id`): muitos para um, filtro da dimensão para a fato.
- `dPalavras` → `dProdutos` (`product_id`): muitos para um.
- `dPalavras` → `dTemas` (`palavra`): muitos para um.
- `dReviewTexto` ↔ `dProdutos` e `dProduct_link_img` ↔ `dProdutos` (`product_id`): um para um.

### Por que tudo se liga à `dProdutos`, e não à `fReview`

A regra de ligar as dimensões à fato depende do **nível de detalhe** de cada tabela. Só a `fReview` está no nível de review; as demais estão no nível de produto (ou produto e palavra), e o ponto em comum entre elas é o produto.

- Ligar `dPalavras` à `fReview` seria muitos para muitos (`product_id` se repete nas duas) e inflaria as contagens.
- Ligar as tabelas 1:1 às duas fatos criaria dois caminhos entre as mesmas tabelas.
- Com a `dProdutos` como dimensão compartilhada, uma segmentação de categoria ou de nota filtra `fReview` e `dPalavras` ao mesmo tempo.

Limite conhecido: o filtro vai da `dProdutos` para as fatos, então um tema selecionado não filtra a `fReview`. Dá para contar **produtos** que citam o tema, mas não **reviews** que o citam.

## 2. Unidade de análise: produto e anúncio

A `dProdutos` tem uma linha por produto (variante), com a coluna `anuncio_id`. Avaliações, nota e engajamento são calculados **uma vez por anúncio** pelas medidas; contagens, preços, descontos, quadrantes e análise de texto são calculados **por produto**. A regra completa, a justificativa e o efeito nos números estão na seção 7 de [`decisoes-de-dados.md`](decisoes-de-dados.md).

## 3. Análise de texto (Customer Insights)

### Pipeline (`powerquery/dPalavras.pq`)

1. Junta `review_title` e `review_content` por produto (`dReviewTexto`, em minúsculas).
2. Separa em palavras por pontuação e símbolos, mantém só letras de a a z (descarta hindi, emoji e números) e palavras com 3 ou mais letras.
3. Remove as stopwords (`dStopwords`, 159 palavras): palavras funcionais do inglês, hindi romanizado e termos sem informação como `product` e `good`.
4. Conta as menções por produto e palavra.

### Temas (`powerquery/dTemas.pq`)

| Grupo | Tema | Palavras |
|---|---|---|
| Valor percebido | Logística | 12 |
| Valor percebido | Preço e desconto | 14 |
| Valor percebido | Qualidade e desempenho | 11 |
| Valor percebido | Atendimento e garantia | 7 |
| Problema | Defeito e falha | 13 |
| Problema | Devolução e troca | 8 |
| Problema | Falsificado e fraude | 6 |
| Problema | Insatisfação | 10 |

**Palavras deixadas de fora de propósito**, por serem ambíguas:

- `issue` e `problem` (aparecem muito em "no issue" e "no problem") e `bad` (em "not bad");
- `cheap` (preço baixo e qualidade ruim) e `service` ("service center");
- `money` (quase sempre em "value for money", o que contaria o mesmo elogio duas vezes junto com `value`);
- Superaquecimento como tema: em Home&Kitchen, `heating` quase sempre é a **função** do produto (chaleira, aquecedor), e as palavras que só indicam problema (`overheating`, `overheated`) somam menos de 5 ocorrências.

### Métricas

- **% de produtos que mencionam o tema** (principal): vai de 0% a 100% e não é inflada por produtos que repetem a palavra.
- **Menções por produto:** média de ocorrências por produto; pode passar de 1 e é sensível a repetições.
- Para engajamento, usa-se a **mediana** de avaliações, não a média, porque a distribuição tem cauda muito longa (poucos anúncios com centenas de milhares de avaliações).

### Limitações

- A contagem é por palavra e **não entende negação**: "not working" conta como `working`.
- Os temas têm listas de tamanhos diferentes, e um tema com mais palavras tende a ter mais menções.
- Mencionar um tema não significa valorizá-lo.
- A base tem cerca de 8 reviews por produto (amostra); as diferenças entre grupos são **associações**, não causas.
- A análise é por produto: variantes do mesmo anúncio repetem as mesmas reviews (cerca de 16% das menções). O efeito é pequeno: os percentuais por tema mudam no máximo 1,4 ponto percentual.

## 4. Segmentações analíticas

Todas são colunas calculadas da `dProdutos` (`dax/medidas.dax`).

### Grupo de nota (`grupo_nota`)

| Grupo | Regra | Produtos |
|---|---|---|
| Ruim | nota até 3,9 | 340 |
| Intermediário | entre 3,9 e 4,2 | 591 |
| Bom | nota acima de 4,2 | 419 |
| (em branco) | produto sem nota válida | 1 |

### Compartimentos de nota (histograma)

O histograma "Distribuição de notas" da página Visão Executiva usa o campo `avaliação`, criado pela interface do Power BI (Novo grupo → Compartimento). Ele agrupa `rating` em compartimentos de **0,1**, ou seja, uma barra para cada valor de nota.

### Faixas de desconto (`faixa_desconto`)

Sobre `discount_percentage`: `0% - 25%` (228 produtos), `25% - 50%` (461), `50% - 75%` (507) e `75% ou mais` (155). O limite inferior de cada faixa é incluído.

### Faixas de preço (`faixa_preco`)

Sobre o preço original em dólar (`actual_price_dollar`): até US$ 5, US$ 5 a 10, US$ 10 a 25, US$ 25 a 50 e acima de US$ 50. Uma coluna numérica (`faixa_preco_ordem`) mantém as faixas na ordem certa nos gráficos.

### Quadrantes (Estrela, Oportunidade, Atenção, Risco)

Coluna calculada `quadrante`. Cada produto é classificado pela sua nota e pelo seu número de avaliações, em relação à **mediana do portfólio**: nota 4,1 e `rating_count` 4.740. Valores iguais à mediana ficam no lado "alto".

| | Nota maior ou igual a 4,1 | Nota abaixo de 4,1 |
|---|---|---|
| **Engajamento alto** (≥ 4.740) | Estrela (478) | Risco (197) |
| **Engajamento baixo** (< 4.740) | Oportunidade (373) | Atenção (303) |

- **Os quadrantes são por produto**, enquanto os gráficos de engajamento mostram a mediana de avaliações por anúncio (3.740 no portfólio). São medidas diferentes, de propósito.
- **Valores em branco** são tratados como zero pelo DAX e caem no lado "baixo": o produto sem nota válida (`B08L12N5H1`) e o produto sem `rating_count` e com nota 3,0 (`B0B94JPY2N`) entram em Atenção, e o sem `rating_count` e com nota 5,0 (`B0BQRJ3C47`) entra em Oportunidade.

## 5. Ressalvas gerais para a leitura do dashboard

- Os comparativos por categoria usam só as categorias com 30+ produtos (quatro categorias); OfficeProducts tem 31. Alguns gráficos de preço e de satisfação mostram todas as nove, e as categorias com 1 ou 2 produtos devem ser lidas com cuidado.
- Os produtos "ruins" se concentram em Electronics e Home&Kitchen, então palavras como `battery` ou `bass` refletem a categoria tanto quanto a qualidade.
- As correlações do dashboard (como desconto × nota) são calculadas por produto e medem associação, não causa.
