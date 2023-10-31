import {justDate, toUtc} from '../DateHelpers';

describe('justDate', () => {
  it('removes the time from a date', () => {
    const date = new Date(2000, 1, 1, 14, 2, 2);
    const actual = justDate(date);

    expect(actual).toEqual(new Date(2000, 1, 1));
  });

  it('removes the time from a string', () => {
    const actual = justDate('2000-01-01 14:02:02');

    expect(actual).toEqual(new Date(2000, 0, 1));
  });
});

describe('toUtc', () => {
  it('converts to utc', () => {
    const date = 'Wed Sep 16 2020 00:00:00 GMT+0100 (BST)';

    const actual = toUtc(date);
    expect(actual).toEqual(new Date('2020-09-16T00:00:00.000Z'));
  });
});
