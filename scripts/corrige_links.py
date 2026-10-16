"""Corrige os links de imagem e de produto da base amazon.csv.

Regras (validadas nas 1.465 linhas):
  - img_link: mantém o domínio, descarta o prefixo /W/WEBP_..../ e o sufixo de
    tamanho (._SX300_SY300_QL70_FMwebp_) e devolve <dominio>/images/I/<ID>.jpg
  - product_link: remove os parâmetros de rastreio a partir de /ref=
  - valida que o ASIN do link (/dp/<ASIN>) é igual ao product_id

Uso:
    python scripts/corrige_links.py [entrada.csv] [saida.csv]
"""
import sys

import pandas as pd

ENTRADA = sys.argv[1] if len(sys.argv) > 1 else "data/raw/amazon.csv"
SAIDA = sys.argv[2] if len(sys.argv) > 2 else "data/processed/links_corrigidos.csv"
MARCADOR = "/images/I/"


def corrige_imagem(url: str) -> str:
    if MARCADOR not in url:
        return url
    dominio = url[: url.index("/images/")]
    codigo = url[url.index(MARCADOR) + len(MARCADOR):].split(".")[0]
    return f"{dominio}{MARCADOR}{codigo}.jpg"


def limpa_produto(url: str) -> str:
    return url.split("/ref=")[0]


def main() -> None:
    df = pd.read_csv(ENTRADA, dtype=str)
    saida = pd.DataFrame(
        {
            "product_id": df["product_id"],
            "img_link_antigo": df["img_link"],
            "img_link_novo": df["img_link"].map(corrige_imagem),
            "product_link": df["product_link"],
            "product_link_limpo": df["product_link"].map(limpa_produto),
        }
    )
    asin = df["product_link"].str.extract(r"/dp/([^/?]+)")[0]
    divergentes = (asin != df["product_id"]).sum()
    saida.to_csv(SAIDA, index=False)
    print(f"{len(saida)} linhas gravadas em {SAIDA}")
    print(f"Linhas em que o ASIN do link difere do product_id: {divergentes}")


if __name__ == "__main__":
    main()
