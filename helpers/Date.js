export function justDate(d) {
    const da = d instanceof Date ? d : new Date(Date.parse(d));
    return new Date(da.getFullYear(), da.getMonth(), da.getDate());
}

export function sameDay(d1, d2) {
    const da = d1 instanceof Date ? d1 : new Date(Date.parse(d1));
    const db = d2 instanceof Date ? d2 : new Date(Date.parse(d2));
    return da.getTime() === db.getTime();
}