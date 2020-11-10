export const justDate = (d) => {
  const da = d instanceof Date ? d : new Date(Date.parse(d));
  return new Date(da.getFullYear(), da.getMonth(), da.getDate());
};

export const toUtc = (d) => {
  const da = d instanceof Date ? d : new Date(Date.parse(d));
  return new Date(Date.UTC(da.getFullYear(), da.getMonth(), da.getDate()));
};

export const sameDay = (d1, d2) => {
  const da = d1 instanceof Date ? d1 : new Date(Date.parse(d1));
  const db = d2 instanceof Date ? d2 : new Date(Date.parse(d2));
  return da.getTime() === db.getTime();
};

export const addYears = (d, y) => {
  return new Date(d.getFullYear() + y, d.getMonth(), d.getDate());
};
