# Decisões de limpeza e preparação dos dados

Tech Challenge — Amazon Product Performance & Customer Insights (Grupo 22)

Base original: `amazon.csv` (Kaggle), **1.465 linhas** e **16 colunas**, com preços em rupias indianas (₹) e todos os links no domínio `amazon.in`.

## Resumo dos números

| Item | Valor |
|---|---|
| Linhas na base original | 1.465 |
| Produtos únicos (`product_id`, cada variante conta como um produto) | 1.351 |
| Anúncios únicos (variantes agrupadas por reviews em comum) | 1.181 |
| Produtos com nota válida | 1.350 |
| Produtos com `rating_count` preenchido | 1.349 |
| Reviews em texto (produto × review) | 10.605 (9.269 `review_id` distintos) |
| Usuários distintos | 9.050 |
| Categorias principais | 9 |

---

## 1. Colunas numéricas

| Coluna | Problema encontrado | Decisão |
|---|---|---|
| `rating` | 1 linha corrompida (`B08L12N5H1`): valor `\|` por erro de aspas no CSV | Erro substituído por nulo; demais linhas tipadas como Número Decimal |
| `rating_count` | Texto com separador de milhar (ex.: `24,269`). 2 nulos na origem: `B0B94JPY2N` (nota 3,0) e `B0BQRJ3C47` (nota 5,0) | Removida a vírgula e convertido para Inteiro. Os 2 nulos foram mantidos: os produtos **têm nota, mas a contagem não foi informada** (dado ausente, e não zero avaliações) |
| `discounted_price`, `actual_price` | Texto com símbolo ₹ e separador de milhar | Removidos ₹ e vírgula; convertido para Número Decimal |
| `discount_percentage` | Texto com `%` | Convertido para Percentual |

**Validações feitas:** nenhum preço nulo; o preço com desconto nunca supera o preço original; o percentual de desconto informado bate com o calculado a partir dos preços (diferença máxima de 0,5 ponto percentual).

## 2. Duplicidade de produtos

- `product_id` deveria ser único, mas **92 produtos** aparecem em mais de uma linha: 206 linhas envolvidas, **114 excedentes**.
- O que difere entre as linhas repetidas de um mesmo produto:

| Campo | Produtos em que difere | Observação |
|---|---|---|
| `product_name`, `category`, `rating` | 0 | Idênticos |
| `rating_count` | 31 | Diferença máxima de 13 avaliações (até 0,2%) |
| Preço (original ou com desconto) | 4 | 3 produtos com `discounted_price` diferente (de ₹90 a ₹200 de diferença) e 1 com `actual_price` diferente |
| `about_product` | 4 | |
| `review_id`, `user_id`, `review_title` | 10 | As linhas repetidas trazem reviews diferentes |
| `review_content` | 18 | |
| `img_link` | 77 | Só variação de URL |
| `product_link` | 92 | Só parâmetros de rastreio de busca |

- **Decisão:** manter, para cada `product_id`, a linha com **maior `rating_count`** (em caso de empate, a primeira ocorrência). A mesma regra vale para `dProdutos`, `dReviewTexto` e `dProduct_link_img`. Os produtos que continuam na base (1.351) ainda passam pelo agrupamento em anúncios descrito na seção 7.
- **Resultado:** 1.465 → **1.351 produtos únicos**.
- **Exceção:** a `fReview` parte da base **antes** da deduplicação, porque as linhas repetidas de 10 produtos trazem reviews diferentes. Deduplicar antes faria perder 7 reviews (10.598 contra 10.605).

## 3. Divisão da coluna `category`

- `category` é uma hierarquia separada por `|` (ex.: `Electronics|HomeTheater,TV&Video|Televisions|SmartTelevisions`), com **2 a 7 níveis**.
- **Decisão:** dividida em 5 colunas (`categoria_principal`, `categoria_nivel2`, `categoria_nivel3` a `categoria_nivel5`).
- Nulos esperados por profundidade da hierarquia (produtos únicos):

| Coluna | Nulos |
|---|---|
| Nível 3 | 8 |
| Nível 4 | 150 |
| Nível 5 | 909 |
| Nível 6 | 1.266 |
| Nível 7 | 1.338 |

- `categoria_principal` tem 9 valores, muito concentrados:

| Categoria | Produtos |
|---|---|
| Electronics | 490 |
| Home&Kitchen | 448 |
| Computers&Accessories | 375 |
| OfficeProducts | 31 |
| MusicalInstruments | 2 |
| HomeImprovement | 2 |
| Toys&Games | 1 |
| Car&Motorbike | 1 |
| Health&PersonalCare | 1 |

- As 3 maiores somam 97,2% dos produtos. **Decisão de análise:** comparativos por categoria usam só categorias com **30+ produtos** (4 categorias); as demais têm amostra pequena demais para qualquer conclusão.

## 4. Colunas de review (produto → review)

- `user_id`, `user_name`, `review_id`, `review_title` e `review_content` vêm **concatenados por vírgula** numa célula por produto: de 1 a 8 itens por linha (mediana 8).
- **Teste de alinhamento** (quantidade de itens igual à de `review_id`):

| Coluna | Alinhamento |
|---|---|
| `user_id` | 100% |
| `user_name` | 99,2% (nomes com vírgula interna) |
| `review_title` | 67,5% |
| `review_content` | 13% (texto livre com vírgulas; 233 linhas trazem links de imagem) |

- **Decisões:**
  - Explodir só `review_id` e `user_id`, juntos e por posição (`List.Zip`); separar os dois pela interface gerou produto cartesiano (8 × 8 linhas por produto).
  - **Excluir `user_name`**: é dado pessoal sem utilidade para as perguntas do desafio e desalinha 0,8% das linhas.
  - Manter `review_title` e `review_content` **concatenados por produto**, em minúsculas (`dReviewTexto`), pois não é possível reconstruir o texto por review de forma confiável.
- **Resultado:** `fReview` com **10.605 linhas** (produto, review, usuário) e 9.050 usuários distintos. Há 9.269 `review_id` distintos: o mesmo `review_id` aparece em mais de um produto, então a **chave da `fReview` é `product_id` + `review_id`**.

## 5. Links (`img_link` e `product_link`)

### 5.1 Problemas encontrados

- `img_link`: parte das imagens não abria.
  - 605 links têm `/W/WEBP_402378-T1/` (321) ou `/T2/` (284) no meio da URL.
  - Os 1.465 têm um sufixo de tamanho e formato (ex.: `._SX300_SY300_QL70_FMwebp_`).
- `product_link`: traz parâmetros de rastreio de busca (`/ref=sr_1_1?qid=...&s=electronics&sr=1-1`) sem valor analítico. Todos os links são `amazon.in`.

### 5.2 Decisão

- Imagem: manter o domínio, descartar o prefixo `/W/WEBP_...` e o sufixo, e remontar `<domínio>/images/I/<ID>.jpg`.
- Produto: remover tudo a partir de `/ref=`.
- Validação: o ASIN do link (`/dp/<ASIN>`) é igual ao `product_id` nas **1.465 linhas**.

| | URL |
|---|---|
| Antes | `https://m.media-amazon.com/images/W/WEBP_402378-T1/images/I/51UsScvHQNL._SX300_SY300_QL70_FMwebp_.jpg` |
| Depois | `https://m.media-amazon.com/images/I/51UsScvHQNL.jpg` |

### 5.3 Resultado

- 1.462 links ficaram em `m.media-amazon.com`; 3 usam `images-na.ssl-images-amazon.com` e mantêm esse domínio.
- Todo o tratamento acontece no Power Query, na consulta `dProduct_link_img` (`powerquery/dProduct_link_img.pq`): 1.351 linhas, relação 1:1 com `dProdutos`, sem arquivo auxiliar nem script externo.
- Não foi preciso extrair o nome do produto a partir do link, porque `product_name` existe na base.

## 6. Moeda

Os preços originais estão em **rupias (₹)**. Para a análise, os valores monetários foram convertidos para **US$** à taxa de **0,0105 US$ por ₹** (cerca de ₹ 95 por dólar), cotação de **08/10/2026**, aplicada **no Power Query**, na consulta `dProdutos`: as colunas `actual_price_dollar` e `discounted_price_dollar` multiplicam `actual_price_rupia` e `discounted_price_rupia` pelo parâmetro `TaxaINRUSD`, que concentra a taxa em um único lugar.

## 7. Variantes de um mesmo anúncio

### 7.1 O problema

`rating` e `rating_count` pertencem à **página do anúncio**. Variantes (cor, tamanho, memória) têm `product_id` diferente, mas compartilham a mesma página e, por isso, as mesmas reviews, nota e quantidade de avaliações. Exemplo: três cabos HDMI com exatamente 426.973 avaliações e nota 4,40. Somar `rating_count` linha a linha contaria as mesmas avaliações várias vezes: o total seria **23,8 milhões**, contra **16,5 milhões** contando cada anúncio uma vez (31% a menos). Os preços e descontos, ao contrário, são de cada variante: em 60 dos 97 anúncios com variantes o preço de tabela difere entre elas (em um caso, de ₹ 700 a ₹ 3.500).

### 7.2 Decisão

- **Cada variante continua sendo um produto**, porque no estoque o iPhone branco e o preto são itens diferentes. Contagem de produtos, preço, desconto, quadrantes e análise de texto são medidos **por produto** (`product_id`).
- **Avaliações, nota e engajamento são medidos por anúncio** (`anuncio_id`): variantes que compartilham reviews são agrupadas e a avaliação conta uma única vez.

| Indicador | Unidade |
|---|---|
| Total de produtos, quadrantes, grupo de nota | Produto |
| Preço original e com desconto, desconto médio, faixas de preço e de desconto | Produto |
| Análise de texto (temas, palavras, bons vs ruins) | Produto |
| Total de avaliações, nota média, média e mediana de avaliações, concentração por categoria | Anúncio |

### 7.3 Como os anúncios são identificados

Cada célula `review_id` traz uma lista de IDs de reviews. **Dois produtos são ligados quando compartilham ao menos um `review_id`**, e a ligação é transitiva (se A compartilha uma review com B, e B outra com C, os três formam um grupo). O **menor `product_id`** em ordem alfabética do grupo vira o `anuncio_id`. Uma review pertence a uma página só, então a mesma review em dois produtos indica a mesma página.

- A regra está na consulta `MapaAnuncios` (`powerquery/MapaAnuncios.pq`), que refaz os grupos a cada atualização. `dProdutos` recebe `anuncio_id` por junção, e continua com uma linha por produto.
- Resultado: **1.351 produtos formam 1.181 anúncios**; 97 anúncios têm variantes, reunindo 267 produtos (o maior tem 8).
- **Validação:** o mesmo resultado saiu de um segundo método independente (a primeira review de cada produto como chave), conferido produto a produto.
- Por que não usar o nome: variantes têm nomes parecidos, mas não iguais, e cortar o nome em poucos caracteres juntaria produtos diferentes. Por que não "mesma nota e mesma contagem": há variantes com contagens que diferem em 1 ou 2 avaliações, e há coincidências entre produtos sem relação.
- As medidas calculam o valor de cada anúncio uma vez (o maior `rating_count` e `rating` entre as variantes visíveis; as variantes diferem em no máximo 13 avaliações, em 18 anúncios, e a nota nunca difere).

### 7.4 Efeito nos números

| | Sem agrupar | Com agrupamento (por anúncio) |
|---|---|---|
| Total de avaliações | 23.802.463 | **16.527.815** |
| Média de avaliações | 17.618 | 13.995 |
| Mediana de avaliações | 4.740 | 3.740 |
| Nota média | 4,09 | 4,08 |
| Avaliações em Electronics / Computers / Home&Kitchen | 59,7% / 26,6% / 12,6% | **50,6% / 29,7% / 18,1%** |

Contagens de produtos (1.351), desconto médio (US$ 25,06 e 46,69%) e quadrantes (478 / 373 / 303 / 197) continuam por produto e não mudam.

### 7.5 Limitações desta escolha

- **Os quadrantes cortam em 4,1 de nota e 4.740 avaliações, a mediana por produto**, enquanto a "Mediana de avaliações" dos gráficos é a mediana por anúncio (3.740 no portfólio). São medidas diferentes, de propósito.
- **A análise de texto é por produto**: variantes do mesmo anúncio repetem o mesmo texto, o que infla as menções em cerca de 16%. Testamos o efeito: os percentuais por tema mudam no máximo 1,4 ponto percentual e a diferença entre produtos bons e ruins se mantém.
- **Gráficos por faixa de preço ou de desconto** podem mostrar o mesmo anúncio em mais de uma barra, quando suas variantes caem em faixas diferentes.
- A `fReview` tem 10.605 linhas porque cada variante guarda suas próprias linhas de reviews (9.269 reviews distintas).

## 8. Limitação da amostra de reviews

As reviews em texto são uma **amostra** (cerca de 8 por produto, no máximo 9), enquanto `rating_count` reflete a população (dezenas de milhares por produto). A análise de texto serve para insights qualitativos e comparativos, não para estimar volume de clientes.
