// dStopwords: palavras ignoradas na análise de texto. Desmarcar "Habilitar carga".
// Inclui palavras funcionais do inglês, hindi romanizado e termos sem informação
// (ex.: product, good). Para ignorar mais palavras, basta acrescentar à lista.
let
    Lista = Text.Split(
        "the and for that this with you your are was were have has had but not can will would could should from they them their there here what when where which who why how all any some more most much many very too also just only than then now even still about after before because while been being does did doing its our out off over into onto upon one two get got getting use used using like make made take took going come came see say said give gave let way thing things lot really quite bit little don isn doesn didn wasn won couldn wouldn hasn haven aren hai hain nahi nhi bahut aur kar ke ki ka ko se bhi ye yeh mein achha accha tha kya product products good amazon review reviews buy bought item purchase purchased ordered order other same time need overall",
        " "
    ),
    Tabela = Table.FromList(Lista, Splitter.SplitByNothing(), {"palavra"}),
    Tipo = Table.TransformColumnTypes(Tabela, {{"palavra", type text}})
in
    Tipo
