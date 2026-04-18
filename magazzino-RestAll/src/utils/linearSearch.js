function linearSearch(wHouseList, element){
    return new Promise((resolve) => {
        wHouseList.map((item) => {
            if(item.codArticolo == element.cod && item.descrizione == element.descr) {
                resolve(1)
            }
        })
        resolve(0)
    })
}
export default linearSearch