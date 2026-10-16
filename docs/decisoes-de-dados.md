# Decisões de limpeza e preparação dos dados

Tech Challenge — Amazon Product Performance & Customer Insights (Grupo 22)

Base original: `amazon.csv` (Kaggle), **1.465 linhas** e **16 colunas**, com preços em rupias indianas (₹) e todos os links no domínio `amazon.in`.

## Resumo dos números

| Item | Valor |
|---|---|
| Linhas na base original | 1.465 |
| Produtos únicos (`product_id`) | 1.351 |
| Produtos com nota válida | 1.350 |
| Produtos com `rating_count` preenchido | 1.349 |
| Reviews em texto (produto × review) | 10.605 |
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

- **Decisão:** manter, para cada `product_id`, a linha com **maior `rating_count`** (em caso de empate, a primeira ocorrência). A mesma regra vale para `dProdutos`, `dReviewTexto` e `dProduct_link_img`.
- **Resultado:** 1.465 → **1.351 produtos únicos**.
- **Exceção:** a `fReview` parte da base **antes** da deduplicação, porque as linhas repetidas de 10 produtos trazem reviews diferentes. Deduplicar antes faria perder 7 reviews (10.598 contra 10.605).

## 3. Divisão da coluna `category`

- `category` é uma hierarquia separada por `|` (ex.: `Electronics|HomeTheater,TV&Video|Televisions|SmartTelevisions`), com **2 a 7 níveis**.
- **Decisão:** dividida em 7 colunas (`categoria_principal`, `subcategoria`, `categoria_nivel3` a `categoria_nivel7`).
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
- A correção está em `powerquery/dProduct_link_img.pq` (tabela `dProduct_link_img`, 1.351 linhas, relação 1:1 com `dProdutos`) e em `scripts/corrige_links.py`, que gera `data/processed/links_corrigidos.csv`. As duas implementações produzem o mesmo resultado.
- O CSV mantém `product_link` original e acrescenta `product_link_limpo` (sem rastreio).
- Não foi preciso extrair o nome do produto a partir do link, porque `product_name` existe na base.

## 6. Nome do produto na tabela de consulta

`product_name` tem em média 127 caracteres, e 90% passam de 60. A coluna `nome_curto` (`dax/medidas.dax`) corta o texto no primeiro `|` (onde a base separa o nome das especificações) e limita a 50 caracteres. O nome completo aparece na dica de ferramenta.

## 7. Moeda

Os preços originais estão em **rupias (₹)**. Para a análise, os valores monetários foram convertidos para **US$** à taxa de **0,0105 US$ por ₹** (cerca de ₹ 95 por dólar), cotação de **08/10/2026**, aplicada **no Power Query**: as colunas `actual_price_dollar` e `discounted_price_dollar` multiplicam os preços em rupias pelo parâmetro `TaxaINRUSD`, que concentra a taxa em um único lugar.

## 8. Variantes de um mesmo anúncio

> **Decisão do grupo:** manter a análise por produto (ASIN), sem agrupar variantes. Os totais de avaliações somam as variantes e isso é tratado como limitação (ver README).

## 9. Limitação da amostra de reviews

As reviews em texto são uma **amostra** (cerca de 8 por produto, no máximo 9), enquanto `rating_count` reflete a população (dezenas de milhares por produto). A análise de texto serve para insights qualitativos e comparativos, não para estimar volume de clientes.
