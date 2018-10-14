export function justDate(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

export function sameDay(d1, d2) {
    const da = d1 instanceof Date ? d1 : new Date(Date.parse(d1));
    const db = d2 instanceof Date ? d2 : new Date(Date.parse(d2));
    return da.getTime() === db.getTime();
}