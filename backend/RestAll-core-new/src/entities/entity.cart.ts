export default interface Cart {
    idUtente: bigint
    items: product[]
}

type product = {
    prezzo: number
    idProdotto: bigint,
    quantita: number
}