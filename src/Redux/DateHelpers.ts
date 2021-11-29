export const toDate = (d: string | number | Date): Date => {
  if (typeof d === 'string') {
    return new Date(Date.parse(d));
  } else if (typeof d === 'number') {
    return new Date(d);
  }
  return d;
};

export const justDate = (d: string | number | Date): Date => {
  const da = toDate(d);
  return new Date(da.getFullYear(), da.getMonth(), da.getDate());
};

export const toUtc = (d: string | number | Date): Date => {
  const da = toDate(d);
  return new Date(Date.UTC(da.getFullYear(), da.getMonth(), da.getDate()));
};

export const sameDay = (
  d1: string | number | Date,
  d2: string | number | Date,
): boolean => toUtc(d1).getTime() === toUtc(d2).getTime();

export const addYears = (d: Date, y: number): Date => {
  return new Date(d.getFullYear() + y, d.getMonth(), d.getDate());
};
