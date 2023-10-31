import {CAGR, CI} from '../Finance';

describe('finance', () => {
  it('CAGR', () => {
    const rate = CAGR(10000, 19500, 3);
    expect(rate).toEqual(24.93);
  });

  it('CI', () => {
    const ci = CI(4.3, 4, 1500, 6);
    expect(ci).toEqual(1938.84);
  });

  it('CAGR and CI', () => {
    const rate = CAGR(1500, 1938.84, 12);
    expect(rate).toEqual(2.16);

    const ci = CI(rate, 1, 1500, 12);
    expect(ci).toEqual(1938.48);
  });
});
