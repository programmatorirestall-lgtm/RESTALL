import Cart from "../entities/entity.cart";
import pool from "../helpers/mysql";

export const addToCart = async (cart: Cart) => {    
    if (!cart || !cart.items || cart.items.length === 0) {
        // Se il carrello è vuoto, elimina solo i prodotti dell'utente
        const conn = await pool.getConnection()
        try {
            await conn.beginTransaction()
            const deleteSQL = 'DELETE FROM cart WHERE idUtente = ?'
            await conn.query(deleteSQL, [cart.idUtente])
            await conn.commit()
            return { affectedRows: 0, message: "Carrello svuotato" }
        } catch (err) {
            await conn.rollback()
            throw err
        } finally {
            await conn.release()
        }
    }

    // Se ci sono prodotti, costruisci l'array per l'INSERT
    let nCart: [bigint, bigint, number, number][] = []
    cart.items.forEach((product) => {
        nCart.push([cart.idUtente, product.idProdotto, product.quantita, product.prezzo]);
    })

    const conn = await pool.getConnection()

    try {
        await conn.beginTransaction()

        const deleteSQL = 'DELETE FROM cart WHERE idUtente = ?'
        await conn.query(deleteSQL, [cart.idUtente])

        const insertSQL = 'INSERT INTO cart (idUtente, idProdotto, quantita, prezzo) VALUES ?'
        const [insertRes] = await conn.query(insertSQL, [nCart])

        await conn.commit()
        return insertRes
    } catch (err) {
        await conn.rollback()
        throw err
    } finally {
        await conn.release()
    }
}


export const getCart = async (idUtente: bigint) => {
    let selectSQL = 'SELECT * from cart WHERE idUtente = ?'
    try{
      let [res] = await pool.query(selectSQL, [idUtente])
      return res as any[];  
    }
    catch(err){
        throw err
    }
}

